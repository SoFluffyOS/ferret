import 'dart:async';

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
      expect(system.startOnBoot, isTrue);

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

  @override
  Future<void> acquireMulticastLock() async {}

  @override
  Future<void> releaseMulticastLock() async {}
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
