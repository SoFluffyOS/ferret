import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:transport/transport.dart';

/// On Windows a refused connect takes about two seconds. A device's fresh
/// address, announced while its stale one is still being dialed, must not
/// be lost.
void main() {
  final engines = <FerretEngine>[];
  final discoveries = <_ManualDiscovery>[];

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    for (final discovery in discoveries) {
      await discovery.close();
    }

    engines.clear();
    discoveries.clear();
  });

  Future<FerretEngine> create(
    String name,
    Discovery discovery, {
    Future<ByteConnection> Function(String host, int port)? connect,
  }) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_WINDOWS,
        formFactor: .FORM_FACTOR_DESKTOP,
      ),
      discovery: discovery,
      port: 0,
      ownAddresses: () async => const {},
      connect: connect,
    );
    engines.add(engine);
    return engine;
  }

  Future<void> trust(
    FerretEngine here,
    FerretEngine there, {
    int? lastPort,
  }) => here.trustStore.save(
    TrustedDevice(
      id: there.identity.deviceId,
      name: there.device.name,
      platform: there.device.platform,
      formFactor: there.device.formFactor,
      publicKey: there.identity.publicKey,
      pairedAt: DateTime(2026),
      lastHost: lastPort == null ? null : '127.0.0.1',
      lastPort: lastPort,
    ),
  );

  test(
    'an address announced during a slow refused dial is dialed next',
    () async {
      final unused = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final stalePort = unused.port;
      await unused.close();

      final phone = await create('Phone', _ManualDiscovery());
      await phone.start();

      final dialed = <int>[];
      final announcer = _ManualDiscovery();
      discoveries.add(announcer);
      final laptop = await create(
        'Laptop',
        announcer,
        connect: (host, port) async {
          dialed.add(port);
          if (port == stalePort) {
            await Future<void>.delayed(const Duration(seconds: 1));
            throw SocketException('Connection refused', port: port);
          }

          return SocketConnection.connect(host, port);
        },
      );
      await trust(laptop, phone, lastPort: stalePort);
      await trust(phone, laptop);
      await laptop.start();

      announcer.hear(
        DiscoveredPeer(
          announce: Announce(
            deviceId: phone.identity.deviceId,
            name: phone.device.name,
            port: phone.port,
          ),
          host: '127.0.0.1',
        ),
      );

      await _until(
        () => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty,
      );
      expect(dialed, [stalePort, phone.port]);
      expect(laptop.sessions, hasLength(1));
      expect(phone.sessions, hasLength(1));
    },
  );
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

class _ManualDiscovery implements Discovery {
  final StreamController<DiscoveredPeer> _peers = .broadcast();

  void hear(DiscoveredPeer peer) => _peers.add(peer);

  Future<void> close() => _peers.close();

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
