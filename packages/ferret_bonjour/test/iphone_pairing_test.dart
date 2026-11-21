import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_bonjour/ferret_bonjour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// A Mac and an iPhone on one network where multicast never leaves the
/// iPhone (no multicast entitlement) and only Bonjour gets through: each
/// shows up in the other's Nearby, and the Mac pairs with the iPhone from
/// its row.
void main() {
  late BonjourNetwork network;
  final engines = <FerretEngine>[];

  setUp(() => network = BonjourNetwork());

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> start(
    String name,
    Platform platform,
    FormFactor formFactor,
  ) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: platform,
        formFactor: formFactor,
      ),
      discovery: CombinedDiscovery([
        BlockedAnnounce(),
        BonjourDiscovery(
          backend: network.toBackend(),
          collectFor: const Duration(milliseconds: 50),
        ),
      ]),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  test('a Mac and an unpaired iPhone find each other and pair', () async {
    final mac = await start(
      'MacBook Pro',
      .PLATFORM_MACOS,
      .FORM_FACTOR_LAPTOP,
    );
    final iphone = await start(
      'iPhone 12 mini',
      .PLATFORM_IOS,
      .FORM_FACTOR_PHONE,
    );

    await until(() => mac.nearby.isNotEmpty && iphone.nearby.isNotEmpty);
    final row = mac.nearby.single;
    expect(row.deviceId, iphone.identity.deviceId);
    expect(row.announce.name, 'iPhone 12 mini');
    expect(row.announce.platform, Platform.PLATFORM_IOS);
    expect(iphone.nearby.single.deviceId, mac.identity.deviceId);
    expect(mac.isDiscoveryBlocked, isFalse);

    unawaited(iphone.pairingPrompts.first.then((prompt) => prompt.accept()));
    final outcome = await mac.pairWithAddress(
      row.host,
      row.port,
      expectedDeviceId: row.deviceId,
      onCode: (_) => true,
    );

    expect(outcome, isA<Paired>());
    await until(() => mac.sessions.isNotEmpty && iphone.sessions.isNotEmpty);
    expect(mac.trustStore.isTrusted(iphone.identity.deviceId), isTrue);
    expect(mac.nearby, isEmpty);
    expect(iphone.nearby, isEmpty);
  });

  test('an iPhone that leaves drops out of Nearby', () async {
    final mac = await start(
      'MacBook Pro',
      .PLATFORM_MACOS,
      .FORM_FACTOR_LAPTOP,
    );
    final iphone = await start(
      'iPhone 12 mini',
      .PLATFORM_IOS,
      .FORM_FACTOR_PHONE,
    );
    await until(() => mac.nearby.isNotEmpty);

    await iphone.stop();
    engines.remove(iphone);

    await until(() => mac.nearby.isEmpty);
  });
}

Future<void> until(
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

/// Bonjour shared by every device on one network: what one offers, the
/// others' browsers find at 127.0.0.1, and it is lost when taken back.
class BonjourNetwork {
  final Map<String, BonjourService> _offered = {};
  final List<_NetworkBrowser> _browsers = [];

  BonjourBackend toBackend() => _NetworkBackend(this);

  void _add(BonjourService service) {
    _offered[service.name] = service;
    for (final browser in _browsers) {
      browser.controller.add(BonjourFound(service));
    }
  }

  void _remove(String name) {
    if (_offered.remove(name) == null) {
      return;
    }

    for (final browser in _browsers) {
      browser.controller.add(BonjourLost(name));
    }
  }
}

class _NetworkBackend implements BonjourBackend {
  _NetworkBackend(this._network);

  final BonjourNetwork _network;

  @override
  Future<BonjourOffer> offer({
    required String name,
    required String type,
    required int port,
    required Map<String, String> txt,
  }) async {
    _network._add(
      BonjourService(
        name: name,
        port: port,
        txt: txt,
        addresses: const ['127.0.0.1'],
      ),
    );
    return _NetworkOffer(() => _network._remove(name));
  }

  @override
  Future<BonjourBrowser> browse(String type) async {
    final browser = _NetworkBrowser(_network);
    _network._browsers.add(browser);
    for (final service in _network._offered.values) {
      Timer.run(() => browser.controller.add(BonjourFound(service)));
    }

    return browser;
  }
}

class _NetworkOffer implements BonjourOffer {
  _NetworkOffer(this._takeBack);

  final void Function() _takeBack;

  @override
  Stream<BonjourFailed> get failures => const Stream.empty();

  @override
  Future<void> stop() async => _takeBack();
}

class _NetworkBrowser implements BonjourBrowser {
  _NetworkBrowser(this._network);

  final BonjourNetwork _network;
  final StreamController<BonjourEvent> controller = .broadcast();

  @override
  Stream<BonjourEvent> get events => controller.stream;

  @override
  Future<void> stop() async => _network._browsers.remove(this);
}

/// The multicast announce on an iPhone: every send refused.
class BlockedAnnounce implements ActiveDiscovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Stream<String> get departures => const Stream.empty();

  @override
  bool get isBlocked => true;

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> scan() async {}

  @override
  Future<void> stop() async {}
}
