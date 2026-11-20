import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart' show Platform;
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';
import 'helpers/memory_discovery.dart';

/// Two real engines on loopback: a Mac lending its keyboard and mouse with
/// ⌃⌥→ to a Linux computer that injects them.
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
    Platform platform,
    RemoteInputFeature feature,
  ) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: MemorySettingsStore(),
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

  late FakeCapture capture;
  late FakeInjector injector;
  late RemoteInputFeature macFeature;
  late RemoteInputFeature pcFeature;
  late FerretEngine pc;

  Future<void> until(bool Function() condition) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      if (condition()) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    fail('Timed out waiting: ${injector.injected} ${injector.releases}');
  }

  Future<ScreenSwitch> pairMacWithPc() async {
    capture = FakeCapture();
    injector = FakeInjector();
    macFeature = RemoteInputFeature(
      injector: FakeInjector.new,
      locker: const UnsupportedScreenLocker(),
      canBeControlled: true,
      canControl: false,
      canSwitchScreens: true,
      capture: () => capture,
      secureInputHolder: () async => null,
    );
    pcFeature = RemoteInputFeature(
      injector: () => injector,
      locker: const UnsupportedScreenLocker(),
      canBeControlled: true,
      canControl: false,
      canSwitchScreens: false,
    );
    final mac = await startEngine('MacBook Air', .PLATFORM_MACOS, macFeature);
    pc = await startEngine('Desk PC', .PLATFORM_LINUX, pcFeature);
    final handle = await pc.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText);
    if (offer == null) {
      fail('The pairing offer should parse');
    }

    offer
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await mac.pairWithOffer(offer), isA<Paired>());
    await until(() => mac.sessions.isNotEmpty && pc.sessions.isNotEmpty);

    final screenSwitch = macFeature.screenSwitch;
    if (screenSwitch == null) {
      fail('A Mac lends its keyboard and mouse');
    }

    await screenSwitch.setEnabled(true);
    await until(() => capture.switchKeysOn ?? false);
    return screenSwitch;
  }

  /// ⌃⌥→ with the owner answering [choice] on the PC.
  Future<void> switchOver(
    ScreenSwitch screenSwitch,
    ConsentChoice choice,
  ) async {
    capture.heldOnStart = {.control, .alt};
    await screenSwitch.next();
    final controlHost = pcFeature.controlHost;
    await until(() => controlHost?.pending != null);
    expect(controlHost?.pending?.kind, ConsentKind.screen);
    expect(controlHost?.pending?.deviceName, 'MacBook Air');
    await controlHost?.answer(choice);
  }

  test('⌃⌥→ asks once, keys and pointer arrive, ⌃⌥⎋ lets go of them', () async {
    final screenSwitch = await pairMacWithPc();
    expect(screenSwitch.targets.single.remoteDevice?.name, 'Desk PC');

    await switchOver(screenSwitch, .allowOnce);
    await until(() => screenSwitch.state.isAway);
    expect(screenSwitch.state.deviceName, 'Desk PC');
    expect(capture.capturing, isTrue);
    expect(pcFeature.controlHost?.active?.deviceName, 'MacBook Air');

    capture.capture([
      captured(.move, x: 5, y: 4),
      captured(.key, code: 0x00, pressed: true, text: 'a'),
      captured(.key, code: 0x00, text: 'a'),
      captured(.modifiers, modifiers: 1),
      captured(.button, pressed: true),
      captured(.button),
      captured(.modifiers, modifiers: 9),
      captured(.key, code: 0x08, pressed: true, modifiers: 9),
    ]);
    await until(() => injector.injected.length >= 8);
    expect(injector.injected, const [
      ModifiersAction({}),
      MoveAction(5, 4),
      TextAction('a'),
      ModifiersAction({.shift}),
      ButtonAction(.left, pressed: true),
      ButtonAction(.left, pressed: false),
      ModifiersAction({.shift, .control}),
      KeyAction(.c, pressed: true, modifiers: {.shift, .control}),
    ]);

    await screenSwitch.home();
    expect(screenSwitch.state.phase, ScreenSwitchPhase.home);
    expect(capture.capturing, isFalse);
    await until(() => injector.releases == 1);
    expect(injector.injected.last, const ModifiersAction({}));
    expect(pcFeature.controlHost?.active, isNotNull);

    capture.capture([captured(.move, x: 9, y: 9)]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(injector.injected, isNot(contains(const MoveAction(9, 9))));

    await screenSwitch.next();
    await until(() => screenSwitch.state.isAway);
    expect(pcFeature.controlHost?.pending, isNull);
    expect(capture.starts, 2);
  });

  test('losing the other computer brings everything back at once', () async {
    final screenSwitch = await pairMacWithPc();
    await switchOver(screenSwitch, .always);
    await until(() => screenSwitch.state.isAway);

    await pc.stop();
    engines.remove(pc);
    await until(() => screenSwitch.state.phase == .home);
    expect(screenSwitch.state.problem, ScreenSwitchProblem.lostConnection);
    expect(capture.capturing, isFalse);
  });

  test('Stop on the other computer brings everything back', () async {
    final screenSwitch = await pairMacWithPc();
    await switchOver(screenSwitch, .allowOnce);
    await until(() => screenSwitch.state.isAway);

    await pcFeature.controlHost?.stop();
    await until(() => screenSwitch.state.phase == .home);
    expect(screenSwitch.state.problem, ScreenSwitchProblem.stopped);
    expect(capture.capturing, isFalse);
  });

  test('a no leaves the keyboard and mouse here', () async {
    final screenSwitch = await pairMacWithPc();
    await switchOver(screenSwitch, .deny);

    await until(() => screenSwitch.state.problem != null);
    expect(screenSwitch.state.problem, ScreenSwitchProblem.denied);
    expect(screenSwitch.state.denial, OutgoingDenial.denied);
    expect(capture.starts, 0);
  });

  test('the tap ending on its own comes home, and says why', () async {
    final screenSwitch = await pairMacWithPc();
    await switchOver(screenSwitch, .allowOnce);
    await until(() => screenSwitch.state.isAway);

    capture.end(.secureInput);
    await until(() => screenSwitch.state.phase == .home);
    expect(screenSwitch.state.problem, ScreenSwitchProblem.secureInput);
    await until(() => injector.releases == 1);

    capture.pressSwitchKey(.next);
    await until(() => screenSwitch.state.isAway);
    capture.end(.homeKey);
    await until(() => screenSwitch.state.phase == .home);
    expect(screenSwitch.state.problem, isNull);
  });

  test('a password field stops the switch before it starts', () async {
    final screenSwitch = await pairMacWithPc();
    capture.secureInput = true;

    await screenSwitch.next();
    expect(screenSwitch.state.problem, ScreenSwitchProblem.secureInput);
    expect(pcFeature.controlHost?.pending, isNull);
  });

  test('missing access asks in context, then opens System Settings', () async {
    final screenSwitch = await pairMacWithPc();
    capture.accessNow = const CaptureAccess(
      inputMonitoring: false,
      accessibility: true,
    );

    await screenSwitch.next();
    expect(screenSwitch.state.problem, ScreenSwitchProblem.needsAccess);
    expect(capture.requests, 1);

    await screenSwitch.next();
    expect(capture.requests, 1);
    expect(capture.settingsOpened, 1);
    expect(pcFeature.controlHost?.pending, isNull);
  });

  test('turning it off lets go of the switch keys', () async {
    final screenSwitch = await pairMacWithPc();

    await screenSwitch.setEnabled(false);
    await until(() => capture.switchKeysOn == false);
    await screenSwitch.next();
    expect(screenSwitch.state.phase, ScreenSwitchPhase.home);
  });
}
