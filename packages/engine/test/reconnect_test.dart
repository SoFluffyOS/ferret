import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

void main() {
  final engines = <FerretEngine>[];
  final proxies = <_Proxy>[];

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    for (final proxy in proxies) {
      await proxy.close();
    }

    engines.clear();
    proxies.clear();
  });

  Future<FerretEngine> startEngine(String name, Discovery discovery) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      discovery: discovery,
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> pair(
    FerretEngine scanner,
    FerretEngine shower, {
    int? port,
  }) async {
    final handle = await shower.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The offer did not parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1')
      ..port = port ?? shower.port;
    expect(await scanner.pairWithOffer(offer), isA<Paired>());
    await _until(
      () => scanner.sessions.isNotEmpty && shower.sessions.isNotEmpty,
    );
  }

  test('a session that stopped answering is replaced right away', () async {
    final laptop = await startEngine('Laptop', _CountingDiscovery());
    final phone = await startEngine('Phone', _CountingDiscovery());
    final proxy = await _Proxy.to(laptop.port);
    proxies.add(proxy);
    await pair(phone, laptop, port: proxy.port);
    final phoneFirst = phone.sessions.single;
    final laptopFirst = laptop.sessions.single;

    proxy.frozen = true;
    await phone.reconnectNow(probeTimeout: const Duration(milliseconds: 300));

    await _until(
      () =>
          phone.sessions.length == 1 &&
          phone.sessions.single != phoneFirst &&
          laptop.sessions.length == 1 &&
          laptop.sessions.single != laptopFirst,
    );
    expect(phoneFirst.isClosed, isTrue);
  });

  test('sessions that still answer are kept', () async {
    final laptop = await startEngine('Laptop', _CountingDiscovery());
    final phone = await startEngine('Phone', _CountingDiscovery());
    await pair(phone, laptop);
    final first = phone.sessions.single;

    await phone.reconnectNow();

    expect(phone.sessions.single, same(first));
    expect(first.isClosed, isFalse);
    expect(await first.checkAlive(), isTrue);
  });

  test('paired devices are dialed at their last known address', () async {
    final laptop = await startEngine('Laptop', _CountingDiscovery());
    final phone = await startEngine('Phone', _CountingDiscovery());
    await pair(phone, laptop);
    final laptopId = laptop.identity.deviceId;
    final phoneId = phone.identity.deviceId;

    final unused = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final deadPort = unused.port;
    await unused.close();
    await _movePort(laptop.trustStore, phoneId, deadPort);
    await _movePort(phone.trustStore, laptopId, deadPort);
    await laptop.sessions.single.close(.GOODBYE_REASON_DUPLICATE);
    await _until(() => phone.sessions.isEmpty && laptop.sessions.isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(phone.sessions, isEmpty);

    await _movePort(phone.trustStore, laptopId, laptop.port);
    await phone.reconnectNow();

    await _until(
      () => phone.sessions.isNotEmpty && laptop.sessions.isNotEmpty,
      timeout: const Duration(seconds: 2),
    );
  });

  test('discovery restarts so new networks are joined', () async {
    final discovery = _CountingDiscovery();
    final phone = await startEngine('Phone', discovery);
    expect(discovery.starts, 1);

    await phone.reconnectNow();

    expect(discovery.starts, 2);
    expect(discovery.isStarted, isTrue);
  });

  test('calls during a reconnect merge into one more run', () async {
    final discovery = _CountingDiscovery();
    final phone = await startEngine('Phone', discovery);

    await Future.wait([
      phone.reconnectNow(),
      phone.reconnectNow(),
      phone.reconnectNow(),
      phone.reconnectNow(),
    ]);

    expect(discovery.starts, 3);
  });

  test('a stopped engine does not reconnect', () async {
    final discovery = _CountingDiscovery();
    final phone = await startEngine('Phone', discovery);
    await phone.stop();

    await phone.reconnectNow();

    expect(discovery.starts, 1);
    expect(discovery.isStarted, isFalse);
  });
}

Future<void> _movePort(TrustStore store, String deviceId, int port) async {
  final trusted = store[deviceId];
  if (trusted == null) {
    fail('$deviceId is not trusted');
  }

  await store.save(trusted.copyWith(lastPort: port));
}

Future<void> _until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Discovery that finds no one and counts how often it started, so tests
/// see only what the engine dials itself.
class _CountingDiscovery implements Discovery {
  int starts = 0;
  bool isStarted = false;

  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {
    starts++;
    isStarted = true;
  }

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async => isStarted = false;
}

/// Forwards TCP to a port and can go silent without closing, like a link
/// that died while a laptop slept.
class _Proxy {
  _Proxy._(this._server) {
    _server.listen(_onClient);
  }

  static Future<_Proxy> to(int port) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    return _Proxy._(server).._target = port;
  }

  final ServerSocket _server;
  final List<Socket> _sockets = [];
  late final int _target;
  bool frozen = false;

  int get port => _server.port;

  Future<void> _onClient(Socket client) async {
    final upstream = await Socket.connect(
      InternetAddress.loopbackIPv4,
      _target,
    );
    _sockets.addAll([client, upstream]);
    _pipe(client, upstream);
    _pipe(upstream, client);
  }

  void _pipe(Socket from, Socket to) {
    from.listen(
      (data) {
        if (!frozen) {
          to.add(data);
        }
      },
      onError: (Object _) => to.destroy(),
      onDone: to.destroy,
    );
  }

  Future<void> close() async {
    for (final socket in _sockets) {
      socket.destroy();
    }

    await _server.close();
  }
}
