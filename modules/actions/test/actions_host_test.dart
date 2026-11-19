import 'dart:async';

import 'package:actions/actions.dart';
import 'package:fake_async/fake_async.dart';
import 'package:ferret_actions/ferret_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/actions.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeSession tablet;
  late FakeComputer computer;
  late FakeRunner runner;
  late ActionsHost actions;

  ActionsHost create({
    Duration consentTimeout = const Duration(seconds: 60),
    Duration countdownLength = const Duration(milliseconds: 40),
    Duration leaveDelay = Duration.zero,
  }) => ActionsHost(
    host: host,
    featureId: ActionsFeature.featureId,
    computer: computer,
    runner: runner,
    settings: ActionsSettings(host.settings),
    consentTimeout: consentTimeout,
    countdownLength: countdownLength,
    commandTimeout: const Duration(seconds: 30),
    leaveDelay: leaveDelay,
  )..start();

  setUp(() async {
    host = await FakeHost.create();
    pixel = FakeSession('pixel');
    tablet = FakeSession('tablet', name: 'Tablet');
    host.sessions = [pixel, tablet];
    computer = FakeComputer();
    runner = FakeRunner();
    actions = create();
  });

  tearDown(() => actions.dispose());

  Future<RunResult> run(FakeSession session, String id) async =>
      (await actions.onRun(session, RunAction(id: id))).result;

  group('consent', () {
    test('the first time a device asks, the owner is asked', () async {
      final reply = run(pixel, ActionIds.sleep);
      await pumpEventQueue();

      expect(actions.pending?.deviceName, 'Pixel 7');
      expect(actions.pending?.action.kind, ActionKind.ACTION_KIND_SLEEP);
      expect(computer.ran, isEmpty);

      await actions.answer(.allowOnce);

      expect(await reply, RunResult.RUN_RESULT_DONE);
      await pumpEventQueue();
      expect(computer.ran, [ComputerAction.sleep]);
      expect(actions.pending, isNull);
    });

    test('Allow once asks again the next time', () async {
      final first = run(pixel, ActionIds.sleep);
      await pumpEventQueue();
      await actions.answer(.allowOnce);
      await first;

      unawaited(run(pixel, ActionIds.sleep));
      await pumpEventQueue();

      expect(actions.pending, isNotNull);
    });

    test('Always allow runs without asking from then on', () async {
      final first = run(pixel, ActionIds.sleep);
      await pumpEventQueue();
      await actions.answer(.always);
      await first;

      expect(await run(pixel, ActionIds.sleep), RunResult.RUN_RESULT_DONE);
      expect(actions.pending, isNull);
    });

    test('Always allow is per device and per action', () async {
      final first = run(pixel, ActionIds.sleep);
      await pumpEventQueue();
      await actions.answer(.always);
      await first;

      unawaited(run(tablet, ActionIds.sleep));
      await pumpEventQueue();
      expect(actions.pending?.deviceId, 'tablet');
      await actions.answer(.deny);

      unawaited(run(pixel, ActionIds.restart));
      await pumpEventQueue();
      expect(actions.pending?.action.id, ActionIds.restart);
    });

    test('one yes covers mute and both volume steps', () async {
      final first = run(pixel, ActionIds.volumeUp);
      await pumpEventQueue();
      await actions.answer(.always);
      expect(await first, RunResult.RUN_RESULT_DONE);

      expect(await run(pixel, ActionIds.mute), RunResult.RUN_RESULT_DONE);
      expect(await run(pixel, ActionIds.volumeDown), RunResult.RUN_RESULT_DONE);
      expect(computer.ran, [
        ComputerAction.volumeUp,
        ComputerAction.toggleMute,
        ComputerAction.volumeDown,
      ]);
    });

    test("Don't allow says no, and keeps saying it for a while", () async {
      final first = run(pixel, ActionIds.restart);
      await pumpEventQueue();
      await actions.answer(.deny);

      expect(await first, RunResult.RUN_RESULT_DENIED);
      expect(await run(pixel, ActionIds.restart), RunResult.RUN_RESULT_DENIED);
      expect(actions.pending, isNull);
      expect(computer.ran, isEmpty);
    });

    test('a question nobody answers ends by itself', () {
      fakeAsync((async) {
        final timed = create(consentTimeout: const Duration(seconds: 60));
        RunResult? result;
        unawaited(
          timed
              .onRun(pixel, RunAction(id: ActionIds.sleep))
              .then((reply) => result = reply.result),
        );
        async.flushMicrotasks();
        expect(timed.pending, isNotNull);

        async.elapse(const Duration(seconds: 61));

        expect(result, RunResult.RUN_RESULT_NOT_ANSWERED);
        expect(timed.pending, isNull);
        expect(computer.ran, isEmpty);
        unawaited(timed.dispose());
      });
    });

    test('a second device is told the computer is busy', () async {
      unawaited(run(pixel, ActionIds.sleep));
      await pumpEventQueue();

      expect(await run(tablet, ActionIds.sleep), RunResult.RUN_RESULT_BUSY);
    });

    test('a device that leaves takes its question with it', () async {
      final reply = run(pixel, ActionIds.sleep);
      await pumpEventQueue();

      actions.onSessionClosed('pixel');

      expect(await reply, RunResult.RUN_RESULT_NOT_ANSWERED);
      expect(actions.pending, isNull);
    });

    test('turned off, nothing runs and nothing is offered', () async {
      await actions.setEnabled(false);
      await pumpEventQueue();

      expect(
        await run(pixel, ActionIds.sleep),
        RunResult.RUN_RESULT_TURNED_OFF,
      );
      expect(host.broadcasts.whereType<ActionList>().last.actions, isEmpty);
    });

    test('the switch on a device page gives and takes Always allow', () async {
      final sleep = actions.offered.firstWhere(
        (action) => action.id == ActionIds.sleep,
      );

      await actions.setAllowed('pixel', sleep, allowed: true);
      expect(await run(pixel, ActionIds.sleep), RunResult.RUN_RESULT_DONE);

      await actions.setAllowed('pixel', sleep, allowed: false);
      unawaited(run(pixel, ActionIds.sleep));
      await pumpEventQueue();
      expect(actions.pending, isNotNull);
    });
  });

  group('routing', () {
    setUp(() async {
      for (final action in actions.grantable) {
        await actions.setAllowed('pixel', action, allowed: true);
      }
    });

    test('each id runs its own action', () async {
      await run(pixel, ActionIds.mute);
      await run(pixel, ActionIds.volumeUp);
      await run(pixel, ActionIds.volumeDown);
      await run(pixel, ActionIds.sleep);
      await pumpEventQueue();

      expect(computer.ran, [
        ComputerAction.toggleMute,
        ComputerAction.volumeUp,
        ComputerAction.volumeDown,
        ComputerAction.sleep,
      ]);
    });

    test('an id nobody offers runs nothing', () async {
      expect(
        await run(pixel, 'rm -rf /'),
        RunResult.RUN_RESULT_UNKNOWN_ACTION,
      );
      expect(computer.ran, isEmpty);
      expect(runner.ran, isEmpty);
    });

    test('what the platform can not do is not offered', () async {
      computer = FakeComputer(supported: {ComputerAction.sleep});
      final limited = create();

      expect(
        [for (final action in limited.offered) action.id],
        [
          ActionIds.sleep,
        ],
      );
      expect(
        (await limited.onRun(pixel, RunAction(id: ActionIds.restart))).result,
        RunResult.RUN_RESULT_UNKNOWN_ACTION,
      );
      await limited.dispose();
    });

    test('a volume step that fails says so', () async {
      computer.works = false;

      expect(await run(pixel, ActionIds.mute), RunResult.RUN_RESULT_FAILED);
      expect(actions.recent.single.result, RunResult.RUN_RESULT_FAILED);
    });

    test('volume steps that work leave no line', () async {
      await run(pixel, ActionIds.volumeUp);

      expect(actions.recent, isEmpty);
    });

    test('the list tells devices ids and names, never a command', () async {
      final custom = await actions.addCustom(
        name: 'Backup',
        commandLine: '~/bin/backup.sh --quick',
      );
      await pumpEventQueue();
      await actions.sendList(pixel);

      final sent = pixel.sentOf<ActionList>().single;
      final backup = sent.actions.singleWhere(
        (action) => action.id == custom.id,
      );
      expect(backup.title, 'Backup');
      expect(backup.kind, ActionKind.ACTION_KIND_CUSTOM);
      expect(sent.toString(), isNot(contains('backup.sh')));
      expect(
        host.broadcasts.whereType<ActionList>().last.actions.map(
          (action) => action.id,
        ),
        contains(custom.id),
      );
      expect(
        sent.actions
            .where((action) => action.confirm)
            .map((action) => action.id),
        [ActionIds.restart, ActionIds.shutDown],
      );
    });
  });

  group('custom actions', () {
    late CustomAction backup;

    setUp(() async {
      backup = await actions.addCustom(
        name: 'Backup',
        commandLine: '/usr/local/bin/backup "My Disk" --quick',
      );
    });

    test('the question shows exactly what will run', () async {
      unawaited(run(pixel, backup.id));
      await pumpEventQueue();

      expect(
        actions.pending?.action.commandLine,
        '/usr/local/bin/backup "My Disk" --quick',
      );
      expect(actions.pending?.action.title, 'Backup');
    });

    test('runs the command split into words, with the timeout', () async {
      runner.outcome = const CommandOutcome(exitCode: 0, output: 'ok\n3 files');
      final reply = actions.onRun(pixel, RunAction(id: backup.id));
      await pumpEventQueue();
      await actions.answer(.always);
      final answered = await reply;

      expect(answered.result, RunResult.RUN_RESULT_DONE);
      expect(answered.exitCode, 0);
      expect(runner.ran.single, [
        '/usr/local/bin/backup',
        'My Disk',
        '--quick',
      ]);
      expect(runner.timeouts.single, const Duration(seconds: 30));
      expect(actions.recent.single.output, '3 files');
      expect(actions.recent.single.deviceName, 'Pixel 7');
    });

    test('a command that fails reports its exit code', () async {
      await actions.setAllowed('pixel', actions.offered.last, allowed: true);
      runner.outcome = const CommandOutcome(exitCode: 2, output: 'no disk');

      final reply = await actions.onRun(pixel, RunAction(id: backup.id));

      expect(reply.result, RunResult.RUN_RESULT_FAILED);
      expect(reply.exitCode, 2);
    });

    test('a command that runs too long is reported as stopped', () async {
      await actions.setAllowed('pixel', actions.offered.last, allowed: true);
      runner.outcome = const CommandOutcome(timedOut: true);

      final reply = await actions.onRun(pixel, RunAction(id: backup.id));

      expect(reply.result, RunResult.RUN_RESULT_TIMED_OUT);
      expect(reply.hasExitCode(), isFalse);
      expect(actions.recent.single.result, RunResult.RUN_RESULT_TIMED_OUT);
    });

    test('what a command printed is never stored', () async {
      await actions.setAllowed('pixel', actions.offered.last, allowed: true);
      runner.outcome = const CommandOutcome(exitCode: 0, output: 'secret');

      await actions.onRun(pixel, RunAction(id: backup.id));

      expect(actions.history.single.output, isEmpty);
      expect(
        '${host.settings.get<Object>(ActionsSettings.historyKey)}',
        isNot(contains('secret')),
      );
    });

    test('a new command line asks every device again', () async {
      await actions.setAllowed('pixel', actions.offered.last, allowed: true);

      await actions.updateCustom(
        backup.id,
        name: 'Backup',
        commandLine: '/usr/local/bin/other',
      );
      unawaited(run(pixel, backup.id));
      await pumpEventQueue();

      expect(actions.pending?.action.commandLine, '/usr/local/bin/other');
    });

    test('a new name keeps Always allow', () async {
      await actions.setAllowed('pixel', actions.offered.last, allowed: true);

      await actions.updateCustom(
        backup.id,
        name: 'Nightly backup',
        commandLine: backup.commandLine,
      );

      expect(await run(pixel, backup.id), RunResult.RUN_RESULT_DONE);
    });

    test('a removed action is gone, with its grants', () async {
      await actions.setAllowed('pixel', actions.offered.last, allowed: true);

      await actions.removeCustom(backup.id);

      expect(await run(pixel, backup.id), RunResult.RUN_RESULT_UNKNOWN_ACTION);
      expect(ActionsSettings(host.settings).allowedFor('pixel'), isEmpty);
    });
  });

  group('countdown', () {
    setUp(() async {
      for (final action in actions.grantable) {
        await actions.setAllowed('pixel', action, allowed: true);
      }
    });

    test('a restart counts down, then happens', () async {
      final reply = run(pixel, ActionIds.restart);
      await pumpEventQueue();

      expect(actions.countdown?.deviceName, 'Pixel 7');
      expect(actions.countdown?.action.id, ActionIds.restart);
      expect(computer.ran, isEmpty);

      expect(await reply, RunResult.RUN_RESULT_DONE);
      await pumpEventQueue();
      expect(actions.countdown, isNull);
      expect(computer.ran, [ComputerAction.restart]);
    });

    test('Cancel during the countdown stops it', () async {
      actions = create(countdownLength: const Duration(seconds: 10));
      for (final action in actions.grantable) {
        await actions.setAllowed('pixel', action, allowed: true);
      }
      final reply = run(pixel, ActionIds.shutDown);
      await pumpEventQueue();
      expect(actions.countdown, isNotNull);

      actions.cancelCountdown();

      expect(await reply, RunResult.RUN_RESULT_CANCELLED);
      await pumpEventQueue();
      expect(actions.countdown, isNull);
      expect(computer.ran, isEmpty);
      expect(actions.recent.single.result, RunResult.RUN_RESULT_CANCELLED);
    });

    test('the countdown lasts ten seconds by default', () {
      fakeAsync((async) {
        final timed = ActionsHost(
          host: host,
          featureId: ActionsFeature.featureId,
          computer: computer,
          runner: runner,
          settings: ActionsSettings(host.settings),
          leaveDelay: Duration.zero,
        );
        unawaited(timed.onRun(pixel, RunAction(id: ActionIds.restart)));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 9));
        expect(timed.countdown, isNotNull);
        expect(computer.ran, isEmpty);

        async.elapse(const Duration(seconds: 2));
        expect(timed.countdown, isNull);
        expect(computer.ran, [ComputerAction.restart]);
        unawaited(timed.dispose());
      });
    });

    test('nothing else starts while it counts down', () async {
      actions = create(countdownLength: const Duration(seconds: 10));
      for (final action in actions.grantable) {
        await actions.setAllowed('pixel', action, allowed: true);
      }
      unawaited(run(pixel, ActionIds.restart));
      await pumpEventQueue();

      expect(await run(pixel, ActionIds.shutDown), RunResult.RUN_RESULT_BUSY);
      actions.cancelCountdown();
    });

    test('sleep needs no countdown', () async {
      expect(await run(pixel, ActionIds.sleep), RunResult.RUN_RESULT_DONE);
      expect(actions.countdown, isNull);
    });

    test('seconds left round up and stop at zero', () {
      final startedAt = DateTime(2026, 11, 19, 9);
      final countdown = ActionCountdown(
        deviceId: 'pixel',
        deviceName: 'Pixel 7',
        action: const OfferedAction(
          id: ActionIds.restart,
          kind: .ACTION_KIND_RESTART,
        ),
        startedAt: startedAt,
        endsAt: startedAt.add(const Duration(seconds: 10)),
      );

      expect(countdown.secondsLeft(startedAt), 10);
      expect(
        countdown.secondsLeft(
          startedAt.add(const Duration(milliseconds: 9100)),
        ),
        1,
      );
      expect(
        countdown.secondsLeft(startedAt.add(const Duration(seconds: 30))),
        0,
      );
    });
  });
}
