import 'package:actions/actions.dart';
import 'package:ferret_actions/ferret_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/actions.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHost host;
  late FakeSession mac;
  late ActionsFeature feature;

  final sleep = Action(id: ActionIds.sleep, kind: .ACTION_KIND_SLEEP);
  final mute = Action(id: ActionIds.mute, kind: .ACTION_KIND_MUTE);

  setUp(() async {
    host = await FakeHost.create();
    mac = FakeSession(
      'mac',
      name: 'MacBook Air',
      flags: const [ActionsFeature.runFlag],
      platform: .PLATFORM_MACOS,
    );
    host.sessions = [mac];
    feature = ActionsFeature(offersActions: false);
    await feature.start(host);
  });

  tearDown(() => feature.stop());

  test('a computer with no built-in actions still runs its own', () async {
    final computer = await FakeHost.create();
    computer.platform = .PLATFORM_LINUX;
    final linux = ActionsFeature(computer: const UnsupportedComputerActions());
    addTearDown(linux.stop);

    await linux.start(computer);

    expect(linux.flags, [ActionsFeature.runFlag]);
    expect(linux.actionsHost, isNotNull);
  });

  test('a phone offers nothing and runs nothing', () async {
    expect(feature.flags, isEmpty);
    expect(feature.actionsHost, isNull);

    final reply = await feature.onEnvelope(
      mac,
      envelopeOf(RunAction(id: ActionIds.sleep), expectsReply: true),
    );

    expect(
      (reply as RunActionReply?)?.result,
      RunResult.RUN_RESULT_UNKNOWN_ACTION,
    );
  });

  test('keeps the list a computer sent until it leaves', () async {
    await feature.onEnvelope(
      mac,
      envelopeOf(ActionList(actions: [sleep, mute])),
    );
    expect(feature.actionsOf('mac'), hasLength(2));

    feature.onSessionClosed(mac);

    expect(feature.actionsOf('mac'), isEmpty);
  });

  test('sends only the id, and keeps how it went', () async {
    mac.answer = (_) => RunActionReply(result: .RUN_RESULT_DENIED);

    final outgoing = await feature.run('mac', sleep);

    expect(mac.requests.single, isA<RunAction>());
    expect((mac.requests.single as RunAction).id, ActionIds.sleep);
    expect(outgoing?.result, RunResult.RUN_RESULT_DENIED);
    expect(outgoing?.deviceName, 'MacBook Air');
    expect(feature.client?.outgoing.single.result, RunResult.RUN_RESULT_DENIED);
  });

  test('a computer that never answers reads as not answered', () async {
    final outgoing = await feature.run('mac', mute);

    expect(outgoing?.result, RunResult.RUN_RESULT_NOT_ANSWERED);
  });

  test('a computer gone right after Sleep reads as asleep', () async {
    mac.answer = (_) {
      host.sessions = [];
      throw StateError('closed');
    };

    final outgoing = await feature.run('mac', sleep);

    expect(outgoing?.result, RunResult.RUN_RESULT_DONE);
  });

  test('a custom action brings its exit code back', () async {
    final backup = Action(
      id: 'custom.1',
      kind: .ACTION_KIND_CUSTOM,
      title: 'Backup',
    );
    mac.answer = (_) => RunActionReply(result: .RUN_RESULT_FAILED, exitCode: 3);

    final outgoing = await feature.run('mac', backup);

    expect(outgoing?.exitCode, 3);
  });

  test('the wait covers the question, the countdown and the command', () {
    expect(feature.replyTimeout, const Duration(seconds: 110));
  });
}
