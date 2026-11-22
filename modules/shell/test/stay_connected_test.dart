import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/shell.dart';
import 'package:transport/transport.dart';

void main() {
  group('StayConnectedViewModel', () {
    test('restricted battery use keeps the card up', () async {
      final system = _FakeSystem()..restricted = true;
      final viewModel = StayConnectedViewModel(system: system);

      await viewModel.refresh();

      expect(viewModel.backgroundRestricted, isTrue);
      expect(viewModel.allSet, isFalse);
    });

    test('everything allowed hides the card', () async {
      final viewModel = StayConnectedViewModel(system: _FakeSystem());

      await viewModel.refresh();

      expect(viewModel.allSet, isTrue);
      expect(viewModel.showsMakerSteps, isFalse);
    });

    test('the maker\'s steps show while Ferret is being stopped', () async {
      final system = _FakeSystem()..maker = .samsung;
      final viewModel = StayConnectedViewModel(system: system);

      await viewModel.refresh();
      expect(viewModel.showsMakerSteps, isFalse);

      system.stopsToday = 2;
      await viewModel.refresh();
      expect(viewModel.showsMakerSteps, isTrue);

      system
        ..stopsToday = 0
        ..restricted = true;
      await viewModel.refresh();
      expect(viewModel.showsMakerSteps, isTrue);
    });

    test('a phone without a maker killer shows no maker steps', () async {
      final system = _FakeSystem()..exempt = false;
      final viewModel = StayConnectedViewModel(system: system);

      await viewModel.refresh();

      expect(viewModel.showsMakerSteps, isFalse);
      expect(viewModel.allSet, isFalse);
    });
  });

  group('starting with the phone', () {
    test('a new install starts off and is asked once', () async {
      final settings = MemorySettingsStore();
      final boot = BootChoice(settings);

      await boot.adopt(hadDevices: false);

      expect(boot.startsOnBoot, isFalse);
      expect(boot.needsAnswer, isTrue);

      await boot.adopt(hadDevices: true);

      expect(boot.startsOnBoot, isFalse);
      expect(boot.needsAnswer, isTrue);
    });

    test(
      'an install from before the question keeps starting, unasked',
      () async {
        final settings = MemorySettingsStore();
        final boot = BootChoice(settings);

        await boot.adopt(hadDevices: true);

        expect(boot.startsOnBoot, isTrue);
        expect(boot.needsAnswer, isFalse);
      },
    );

    test('an install that had turned it off keeps it off, unasked', () async {
      final settings = MemorySettingsStore({BootChoice.startKey: false});
      final boot = BootChoice(settings);

      await boot.adopt(hadDevices: true);

      expect(boot.startsOnBoot, isFalse);
      expect(boot.needsAnswer, isFalse);
    });

    test('nothing is asked before the install was sorted out', () {
      expect(BootChoice(MemorySettingsStore()).needsAnswer, isFalse);
    });

    test('Yes turns it on and the question is gone', () async {
      final settings = MemorySettingsStore();
      await BootChoice(settings).adopt(hadDevices: false);
      final viewModel = StayConnectedViewModel(
        system: _FakeSystem(),
        settings: settings,
      );
      await viewModel.refresh();
      expect(viewModel.asksAboutBoot, isTrue);
      expect(viewModel.allSet, isFalse);

      await viewModel.answerBoot(start: true);

      expect(BootChoice(settings).startsOnBoot, isTrue);
      expect(viewModel.asksAboutBoot, isFalse);
      expect(viewModel.allSet, isTrue);
    });

    test('Not now keeps it off and is remembered', () async {
      final settings = MemorySettingsStore();
      await BootChoice(settings).adopt(hadDevices: false);
      final viewModel = StayConnectedViewModel(
        system: _FakeSystem(),
        settings: settings,
      );

      await viewModel.answerBoot(start: false);
      await BootChoice(settings).adopt(hadDevices: true);

      expect(BootChoice(settings).startsOnBoot, isFalse);
      expect(
        StayConnectedViewModel(
          system: _FakeSystem(),
          settings: settings,
        ).asksAboutBoot,
        isFalse,
      );
    });

    testWidgets('the phone follows the answer', (tester) async {
      final system = _FakeSystem();
      late FerretEngine engine;
      late SystemBinding binding;
      await tester.runAsync(() async {
        engine = await _engine();
        binding = SystemBinding(
          engine: engine,
          host: EngineHost(engine),
          pause: PauseController(engine),
          system: system,
        );
        await binding.start();
      });
      expect(system.startOnBoot, isFalse);
      expect(BootChoice(engine.settings).needsAnswer, isTrue);

      await tester.runAsync(() async {
        await BootChoice(engine.settings).answer(start: true);
        await Future<void>.delayed(Duration.zero);
      });

      expect(system.startOnBoot, isTrue);

      await tester.runAsync(() async {
        await binding.dispose();
        await engine.stop();
      });
    });
  });

  group('SystemBinding', () {
    testWidgets('coming back to the app starts a service Android took down', (
      tester,
    ) async {
      final system = _FakeSystem();
      late FerretEngine engine;
      late SystemBinding binding;
      await tester.runAsync(() async {
        engine = await _engine();
        binding = SystemBinding(
          engine: engine,
          host: EngineHost(engine),
          pause: PauseController(engine),
          system: system,
        );
        await binding.start();
      });
      expect(system.starts, 1);
      expect(system.startOnBoot, isFalse);

      system.running = false;
      tester.binding.handleAppLifecycleStateChanged(.resumed);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      expect(system.starts, 2);

      tester.binding.handleAppLifecycleStateChanged(.resumed);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      expect(system.starts, 2);

      await tester.runAsync(() async {
        await binding.dispose();
        await engine.stop();
      });
    });

    testWidgets('holds the multicast lock only while someone looks or a '
        'paired device is missing, never while paused', (tester) async {
      final system = _FakeSystem();
      late FerretEngine engine;
      late SystemBinding binding;
      late PauseController pause;
      Future<void> settle() =>
          tester.runAsync(() => Future<void>.delayed(Duration.zero));

      await tester.runAsync(() async {
        engine = await _engine();
        await engine.start();
        pause = PauseController(engine);
        binding = SystemBinding(
          engine: engine,
          host: EngineHost(engine),
          pause: pause,
          system: system,
        );
        await binding.start();
      });
      expect(system.lockHeld, isFalse, reason: 'nothing paired, nobody looks');

      final nearby = engine.multicastNeed.hold('nearby');
      await settle();
      expect(system.lockHeld, isTrue, reason: 'Add a device is open');

      await tester.runAsync(() => pause.pause());
      await settle();
      expect(system.lockHeld, isFalse, reason: 'paused');

      await tester.runAsync(() => pause.resume());
      await settle();
      expect(system.lockHeld, isTrue);

      nearby.release();
      await settle();
      expect(system.lockHeld, isFalse);

      await tester.runAsync(
        () => engine.trustStore.save(
          TrustedDevice(
            id: 'abcdabcdabcdabcd',
            name: 'MacBook Pro',
            platform: .PLATFORM_MACOS,
            formFactor: .FORM_FACTOR_LAPTOP,
            publicKey: Uint8List(32),
            pairedAt: DateTime(2026),
          ),
        ),
      );
      await settle();
      expect(system.lockHeld, isTrue, reason: 'MacBook Pro is not connected');

      await tester.runAsync(() async {
        await binding.dispose();
        await engine.stop();
      });
    });
  });
}

Future<FerretEngine> _engine() => FerretEngine.create(
  secrets: MemorySecretStore(),
  settings: MemorySettingsStore(),
  device: const LocalDevice(
    name: 'Phone',
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
  ),
  discovery: _SilentDiscovery(),
  port: 0,
);

class _FakeSystem extends Fake implements FerretSystem {
  bool restricted = false;
  bool exempt = true;
  DeviceMaker maker = .other;
  int stopsToday = 0;
  bool running = false;
  bool? startOnBoot;
  int starts = 0;

  @override
  bool get isAndroid => true;

  @override
  Stream<NetworkChange> get networkChanges => const Stream.empty();

  @override
  Stream<PauseState> get pauseChanges => const Stream.empty();

  @override
  Future<bool> areNotificationsAllowed() async => true;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async => exempt;

  @override
  Future<bool> isBackgroundRestricted() async => restricted;

  @override
  Future<DeviceMaker> deviceMaker() async => maker;

  @override
  Future<int> serviceStopsToday({DateTime? now}) async => stopsToday;

  @override
  Future<bool> canRequestAddTile() async => false;

  @override
  Future<void> setStartOnBoot(bool enabled) async => startOnBoot = enabled;

  @override
  Future<bool> isServiceRunning() async => running;

  @override
  Future<void> startService() async {
    starts++;
    running = true;
  }

  @override
  Future<PauseState> pauseState() async => PauseState.running;

  @override
  Future<void> updateStatus(List<String> connectedDevices) async {}

  @override
  Future<void> setPause(PauseState pause) async {}

  bool lockHeld = false;

  @override
  Future<void> acquireMulticastLock() async => lockHeld = true;

  @override
  Future<void> releaseMulticastLock() async => lockHeld = false;
}

class _SilentDiscovery implements Discovery {
  @override
  Stream<DiscoveredPeer> get peers => const Stream.empty();

  @override
  Future<void> start(Announce self) async {}

  @override
  Future<void> announceNow() async {}

  @override
  Future<void> stop() async {}
}
