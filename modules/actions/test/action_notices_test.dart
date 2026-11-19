import 'dart:async';

import 'package:actions/actions.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/actions.dart';

import 'helpers/fakes.dart';

class FakeNotifier implements LocalNotifier {
  final Map<String, LocalNotice> shown = {};
  final StreamController<NoticeResponse> _responses = .broadcast();

  void respond(String noticeId, [String? actionId]) => _responses.add(
    NoticeResponse(noticeId: noticeId, actionId: actionId),
  );

  @override
  Future<void> show(LocalNotice notice) async => shown[notice.id] = notice;

  @override
  Future<void> cancel(String id) async => shown.remove(id);

  @override
  Stream<NoticeResponse> get responses => _responses.stream;
}

void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeComputer computer;
  late ActionsHost actions;
  late FakeNotifier notifier;
  late ActionNotices notices;
  late int reveals;

  setUp(() async {
    host = await FakeHost.create();
    pixel = FakeSession('pixel');
    host.sessions = [pixel];
    computer = FakeComputer();
    actions = ActionsHost(
      host: host,
      featureId: ActionsFeature.featureId,
      computer: computer,
      runner: FakeRunner(),
      settings: ActionsSettings(host.settings),
      countdownLength: const Duration(seconds: 10),
      leaveDelay: Duration.zero,
    )..start();
    notifier = FakeNotifier();
    reveals = 0;
    notices = ActionNotices(
      host: actions,
      notifier: notifier,
      l10n: lookupActionsLocalizations(const Locale('en')),
      reveal: () async => reveals++,
      computer: .mac,
    )..start();
  });

  tearDown(() async {
    await notices.dispose();
    await actions.dispose();
  });

  test('the question is a notice with three answers', () async {
    final reply = actions.onRun(pixel, RunAction(id: ActionIds.sleep));
    await settle();

    final notice = notifier.shown[ActionNotices.consentNotice];
    expect(notice?.title, 'Let Pixel 7 put this Mac to sleep?');
    expect(notice?.category, ActionNotices.consentNotice);

    notifier.respond(ActionNotices.consentNotice, ActionNotices.alwaysAction);
    expect((await reply).result, RunResult.RUN_RESULT_DONE);
    await settle();

    expect(notifier.shown, isEmpty);
    expect(ActionsSettings(host.settings).allowedFor('pixel'), [
      ActionIds.sleep,
    ]);
  });

  test("a custom action's notice says exactly what runs", () async {
    final backup = await actions.addCustom(
      name: 'Backup',
      commandLine: '~/bin/backup.sh --quick',
    );
    unawaited(actions.onRun(pixel, RunAction(id: backup.id)));
    await settle();

    final notice = notifier.shown[ActionNotices.consentNotice];
    expect(notice?.title, 'Let Pixel 7 run “Backup” on this Mac?');
    expect(notice?.body, contains('Runs: ~/bin/backup.sh --quick'));

    notifier.respond(ActionNotices.consentNotice, ActionNotices.denyAction);
    await settle();
    expect(actions.pending, isNull);
  });

  test('the countdown is a notice with Cancel', () async {
    final reply = actions.onRun(pixel, RunAction(id: ActionIds.shutDown));
    await settle();
    notifier.respond(
      ActionNotices.consentNotice,
      ActionNotices.allowOnceAction,
    );
    await settle();

    final notice = notifier.shown[ActionNotices.countdownNotice];
    expect(notice?.title, 'Pixel 7 is shutting down this Mac');

    notifier.respond(ActionNotices.countdownNotice, ActionNotices.cancelAction);

    expect((await reply).result, RunResult.RUN_RESULT_CANCELLED);
    await settle();
    expect(notifier.shown, isEmpty);
    expect(computer.ran, isEmpty);
  });

  test('tapping a notice itself brings Ferret to the front', () async {
    unawaited(actions.onRun(pixel, RunAction(id: ActionIds.sleep)));
    await settle();

    notifier.respond(ActionNotices.consentNotice);
    await settle();

    expect(reveals, 1);
    expect(actions.pending, isNotNull);
  });
}
