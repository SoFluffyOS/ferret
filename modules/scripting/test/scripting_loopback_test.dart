@TestOn('mac-os || linux')
library;

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripting/scripting.dart';

import 'helpers/memory_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryDiscoveryBus bus;
  final engines = <FerretEngine>[];

  setUp(() => bus = MemoryDiscoveryBus());

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> startEngine(
    String name,
    ScriptingFeature feature,
  ) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [feature],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<void> until(bool Function() condition) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      if (condition()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    fail('Timed out waiting');
  }

  Future<(String, String)> pair(FerretEngine laptop, FerretEngine phone) async {
    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await phone.pairWithOffer(offer), isA<Paired>());
    await until(() => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty);

    return (phone.sessions.single.remoteDeviceId, laptop.identity.deviceId);
  }

  test('a notice is refused until the owner allows that computer', () async {
    final laptopFeature = ScriptingFeature();
    final phoneFeature = ScriptingFeature();
    final laptop = await startEngine('Laptop', laptopFeature);
    final phone = await startEngine('Phone', phoneFeature);
    final (laptopId, _) = await pair(laptop, phone);
    final phoneId = laptop.sessions.single.remoteDeviceId;
    final shown = <ScriptNoticeArrived>[];
    phoneFeature.notices.listen(shown.add);

    expect(phoneFeature.settings.allowsNotices(laptopId), isFalse);
    expect(
      await laptopFeature.notify(phoneId, 'Build done', 'All green'),
      'not_allowed',
    );
    expect(shown, isEmpty);

    await phoneFeature.settings.setAllowsNotices(laptopId, allowed: true);

    expect(
      await laptopFeature.notify(phoneId, 'Build done', 'All green'),
      'shown',
    );
    await until(() => shown.isNotEmpty);
    expect(shown.single.title, 'Build done');
    expect(shown.single.body, 'All green');
    expect(shown.single.deviceName, 'Laptop');
  });

  test('empty notices and floods are dropped', () async {
    final laptopFeature = ScriptingFeature();
    final phoneFeature = ScriptingFeature(limit: NoticeLimit(perMinute: 2));
    final laptop = await startEngine('Laptop', laptopFeature);
    final phone = await startEngine('Phone', phoneFeature);
    final (laptopId, _) = await pair(laptop, phone);
    final phoneId = laptop.sessions.single.remoteDeviceId;
    await phoneFeature.settings.setAllowsNotices(laptopId, allowed: true);

    expect(await laptopFeature.notify(phoneId, ' ', ''), 'empty');
    expect(await laptopFeature.notify(phoneId, 'One', ''), 'shown');
    expect(await laptopFeature.notify(phoneId, 'Two', ''), 'shown');
    expect(await laptopFeature.notify(phoneId, 'Three', ''), 'too_many');
  });

  test('a device that is not connected is unreachable', () async {
    final laptopFeature = ScriptingFeature();
    await startEngine('Laptop', laptopFeature);

    expect(await laptopFeature.notify('nobody', 'Hi', ''), 'unreachable');
  });
}
