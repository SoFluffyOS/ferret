@TestOn('mac-os || linux')
library;

import 'package:actions/actions.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_actions/ferret_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/actions.dart';

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

  Future<FerretEngine> startEngine(String name, ActionsFeature feature) async {
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

  Future<String> pair(FerretEngine laptop, FerretEngine phone) async {
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

    return phone.sessions.single.remoteDeviceId;
  }

  test(
    'a phone gets the list, asks, the owner allows, the computer sleeps',
    () async {
      final computer = FakeComputer();
      final laptopFeature = ActionsFeature(
        computer: computer,
        runner: FakeRunner(),
        offersActions: true,
        leaveDelay: const Duration(milliseconds: 20),
      );
      final phoneFeature = ActionsFeature(
        computer: const UnsupportedComputerActions(),
        offersActions: false,
      );
      final laptop = await startEngine('Laptop', laptopFeature);
      final phone = await startEngine('Phone', phoneFeature);
      final laptopId = await pair(laptop, phone);
      final actionsHost = laptopFeature.actionsHost;
      if (actionsHost == null) {
        fail('The laptop should offer actions');
      }

      await until(() => phoneFeature.actionsOf(laptopId).isNotEmpty);
      final offered = phoneFeature.actionsOf(laptopId);
      expect(
        [for (final action in offered) action.id],
        [
          ActionIds.sleep,
          ActionIds.restart,
          ActionIds.shutDown,
          ActionIds.mute,
          ActionIds.volumeUp,
          ActionIds.volumeDown,
        ],
      );
      expect(laptopFeature.actionsOf(phone.identity.deviceId), isEmpty);

      final sleep = offered.first;
      final asked = phoneFeature.run(laptopId, sleep);
      await until(() => actionsHost.pending != null);
      expect(actionsHost.pending?.deviceName, 'Phone');
      expect(phoneFeature.client?.isWaiting(laptopId, sleep.id), isTrue);

      await actionsHost.answer(.always);

      expect((await asked)?.result, RunResult.RUN_RESULT_DONE);
      await until(() => computer.ran.isNotEmpty);
      expect(computer.ran, [ComputerAction.sleep]);

      final again = await phoneFeature.run(laptopId, sleep);
      expect(again?.result, RunResult.RUN_RESULT_DONE);
      expect(actionsHost.pending, isNull);
    },
  );

  test('a new custom action reaches the phone, and its command is stopped '
      'after the timeout', () async {
    final laptopFeature = ActionsFeature(
      computer: FakeComputer(),
      offersActions: true,
      commandTimeout: const Duration(milliseconds: 300),
    );
    final phoneFeature = ActionsFeature(
      computer: const UnsupportedComputerActions(),
      offersActions: false,
    );
    final laptop = await startEngine('Laptop', laptopFeature);
    final phone = await startEngine('Phone', phoneFeature);
    final laptopId = await pair(laptop, phone);
    final actionsHost = laptopFeature.actionsHost;
    if (actionsHost == null) {
      fail('The laptop should offer actions');
    }

    final slow = await actionsHost.addCustom(
      name: 'Slow',
      commandLine: '/bin/sleep 30',
    );
    await until(
      () => phoneFeature
          .actionsOf(laptopId)
          .any((action) => action.id == slow.id),
    );
    final action = phoneFeature
        .actionsOf(laptopId)
        .singleWhere((action) => action.id == slow.id);
    expect(action.title, 'Slow');

    final watch = Stopwatch()..start();
    final asked = phoneFeature.run(laptopId, action);
    await until(() => actionsHost.pending != null);
    await actionsHost.answer(.allowOnce);
    final outcome = await asked;

    expect(outcome?.result, RunResult.RUN_RESULT_TIMED_OUT);
    expect(outcome?.exitCode, isNull);
    expect(watch.elapsed, lessThan(const Duration(seconds: 10)));
    expect(actionsHost.recent.single.result, RunResult.RUN_RESULT_TIMED_OUT);
  });
}
