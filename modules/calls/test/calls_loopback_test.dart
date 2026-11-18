import 'package:calls/calls.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/calls.dart';
import 'package:protocol/protocol.dart' as proto;

import 'support/fakes.dart';

void main() {
  late MemoryDiscoveryBus bus;
  late FakePhone telephony;
  late FerretEngine laptop;
  late FerretEngine phone;
  late CallsFeature onLaptop;
  late CallsFeature onPhone;
  final engines = <FerretEngine>[];

  Future<FerretEngine> startEngine(
    String name,
    proto.Platform platform,
    CallsFeature feature, {
    bool callsOn = false,
  }) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore({CallsSettings.enabledKey: callsOn}),
      device: LocalDevice(
        name: name,
        platform: platform,
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

  Future<void> pair({bool callsOn = true}) async {
    onLaptop = CallsFeature();
    onPhone = CallsFeature(phone: telephony);
    laptop = await startEngine('MacBook', .PLATFORM_MACOS, onLaptop);
    phone = await startEngine(
      'Pixel',
      .PLATFORM_ANDROID,
      onPhone,
      callsOn: callsOn,
    );

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
    await until(() => onLaptop.linkOf(phone.identity.deviceId) != null);
  }

  FeatureHealth? healthOf(FerretEngine engine, CallsFeature feature) =>
      CallsFeatureUi.withFeature(feature).healthFor(
        FeatureContext(
          engine: engine,
          navigatorKey: GlobalKey<NavigatorState>(),
          notifier: FakeNotifier(),
        ),
        engine.devices.single,
      );

  setUp(() {
    bus = MemoryDiscoveryBus();
    telephony = FakePhone()..contact = alex();
  });

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  test('a call rings on the computer, is answered there, and ends', () async {
    await pair();

    telephony.ring('+15550100');
    await until(
      () => onLaptop.remoteCalls.any((call) => call.call.contactName == 'Alex'),
    );
    final ringing = onLaptop.remoteCalls.single;

    final outcome = await onLaptop.answer(ringing);
    telephony.offHook();
    await until(() => onLaptop.remoteCalls.any((call) => !call.isRinging));
    final active = onLaptop.remoteCalls.single;

    final hungUp = await onLaptop.end(active);
    telephony.idle();
    await until(() => onLaptop.remoteCalls.isEmpty);

    expect(ringing.deviceName, 'Pixel');
    expect(ringing.call.number, '+15550100');
    expect(ringing.call.photoJpeg, [1, 2, 3]);
    expect(outcome, CommandOutcome.ok);
    expect(telephony.answered, 1);
    expect(active.call.state, CallState.CALL_STATE_ACTIVE);
    expect(active.connectedAt, isNotNull);
    expect(hungUp, CommandOutcome.ok);
    expect(telephony.ended, 1);
  });

  test('the computer dials, silences and reads recent calls', () async {
    telephony.log = [platformLogEntry(), platformLogEntry(id: '6')];
    await pair();
    final phoneId = phone.identity.deviceId;

    final dialed = await onLaptop.dial(phoneId, '555 0100');
    final log = await onLaptop.fetchCallLog(phoneId);
    telephony.idle();
    telephony.ring();
    await until(() => onLaptop.remoteCalls.isNotEmpty);
    final silenced = await onLaptop.silence(onLaptop.remoteCalls.single);

    expect(dialed, CommandOutcome.ok);
    expect(telephony.dialed, ['5550100']);
    expect(log.problem, isNull);
    expect(log.entries.map((entry) => entry.id), ['7', '6']);
    expect(silenced, CommandOutcome.ok);
    expect(telephony.silenced, 1);
  });

  test('a command for a call that is over says so', () async {
    await pair();
    telephony.ring();
    await until(() => onLaptop.remoteCalls.isNotEmpty);
    final ringing = onLaptop.remoteCalls.single;
    telephony.idle();
    await until(() => onLaptop.remoteCalls.isEmpty);

    expect(await onLaptop.answer(ringing), CommandOutcome.noCall);
    expect(telephony.answered, 0);
  });

  test('health is what the phone answered, on both sides', () async {
    await pair();

    final onComputer = healthOf(laptop, onLaptop);
    final onThePhone = healthOf(phone, onPhone);

    expect(onComputer?.state, FeatureHealthState.ok);
    expect(onComputer?.reason, 'Calls on Pixel show up here.');
    expect(onThePhone?.state, FeatureHealthState.ok);
    expect(onThePhone?.reason, "MacBook sees this phone's calls.");
  });

  test('health says when calls are off on the phone', () async {
    await pair(callsOn: false);

    final onComputer = healthOf(laptop, onLaptop);
    final onThePhone = healthOf(phone, onPhone);
    final log = await onLaptop.fetchCallLog(phone.identity.deviceId);

    expect(onComputer?.state, FeatureHealthState.off);
    expect(onComputer?.reason, 'Calls are off on Pixel.');
    expect(onThePhone?.state, FeatureHealthState.off);
    expect(log.problem, CallLogProblem.disabled);
  });

  test('health asks for the permission the phone lacks', () async {
    telephony.granted = noPermissions();
    await pair();

    final onComputer = healthOf(laptop, onLaptop);
    final onThePhone = healthOf(phone, onPhone);

    expect(onComputer?.state, FeatureHealthState.needsAttention);
    expect(
      onComputer?.reason,
      'Pixel needs the Phone permission to see calls.',
    );
    expect(onThePhone?.state, FeatureHealthState.needsAttention);
  });

  test('the phone learns about a new permission while connected', () async {
    telephony.granted = noPermissions();
    await pair();
    final phoneId = phone.identity.deviceId;

    telephony.afterRequest = allPermissions();
    await onPhone.requestPermissions();
    await until(
      () => onLaptop.linkOf(phoneId)?.status?.canSeeCalls ?? false,
    );

    expect(healthOf(laptop, onLaptop)?.state, FeatureHealthState.ok);
  });
}
