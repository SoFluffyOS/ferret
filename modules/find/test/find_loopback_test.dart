import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:find/find.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/find.dart';

import 'helpers/fakes.dart';
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
    FakeFindPlatform platform,
  ) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
      device: LocalDevice(
        name: name,
        platform: .PLATFORM_LINUX,
        formFactor: .FORM_FACTOR_LAPTOP,
      ),
      features: [FindFeature(platform: () => platform)],
      discovery: bus.join(),
      port: 0,
    );
    await engine.start();
    engines.add(engine);
    return engine;
  }

  Future<(FerretEngine, FerretEngine)> pair(
    FakeFindPlatform laptopPlatform,
    FakeFindPlatform phonePlatform,
  ) async {
    final laptop = await startEngine('Laptop', laptopPlatform);
    final phone = await startEngine('Phone', phonePlatform);
    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await phone.pairWithOffer(offer), isA<Paired>());
    await _until(() => laptop.sessions.isNotEmpty && phone.sessions.isNotEmpty);
    return (laptop, phone);
  }

  FindFeature findOf(FerretEngine engine) {
    final feature = engine.feature<FindFeature>();
    if (feature == null) {
      fail('The find feature should be registered');
    }

    return feature;
  }

  test('the laptop rings the phone, and hears when it is found', () async {
    final phonePlatform = FakeFindPlatform();
    final (laptop, phone) = await pair(FakeFindPlatform(), phonePlatform);
    final laptopFind = findOf(laptop);
    final phoneFind = findOf(phone);
    final phoneId = phone.identity.deviceId;
    await _until(() => laptopFind.remoteInfo(phoneId) != null);

    final ring = await laptopFind.ring(phoneId);

    expect(ring.phase, OutgoingPhase.ringing);
    expect(phonePlatform.playing?.body, contains('Laptop'));
    expect(phonePlatform.audio?.volume, 7);
    expect(laptopFind.remoteInfo(phoneId)?.info?.ringsWhenSilent, isTrue);

    await phoneFind.foundIt();
    await _until(() => laptopFind.outgoingFor(phoneId)?.phase == .found);

    expect(phonePlatform.playing, isNull);
    expect(phonePlatform.audio?.volume, 3);
    expect(phoneFind.localRing.reason, StopReason.STOP_REASON_FOUND);
  });

  test('the laptop stops the ring from afar', () async {
    final phonePlatform = FakeFindPlatform();
    final (laptop, phone) = await pair(FakeFindPlatform(), phonePlatform);
    final laptopFind = findOf(laptop);
    final phoneId = phone.identity.deviceId;

    await laptopFind.ring(phoneId);
    await laptopFind.stopRinging(phoneId);

    expect(laptopFind.outgoingFor(phoneId)?.phase, OutgoingPhase.stoppedHere);
    expect(phonePlatform.playing, isNull);
    expect(
      findOf(phone).localRing.reason,
      StopReason.STOP_REASON_STOPPED_REMOTELY,
    );
  });
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
