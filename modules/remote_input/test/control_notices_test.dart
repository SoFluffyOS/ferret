import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';

class FakeNotifier implements LocalNotifier {
  final Map<String, LocalNotice> shown = {};
  final List<String> cancelled = [];
  final StreamController<NoticeResponse> _responses = .broadcast();

  void respond(String noticeId, [String? actionId]) => _responses.add(
    NoticeResponse(noticeId: noticeId, actionId: actionId),
  );

  @override
  Future<void> show(LocalNotice notice) async => shown[notice.id] = notice;

  @override
  Future<void> cancel(String id) async {
    shown.remove(id);
    cancelled.add(id);
  }

  @override
  Stream<NoticeResponse> get responses => _responses.stream;
}

void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeInjector injector;
  late ControlHost control;
  late FakeNotifier notifier;
  late ControlNotices notices;
  late int reveals;

  setUp(() async {
    host = await FakeHost.create();
    pixel = FakeSession('pixel', name: 'Pixel');
    host.sessions = [pixel];
    injector = FakeInjector();
    control = ControlHost(
      host: host,
      featureId: RemoteInputFeature.featureId,
      injector: injector,
      settings: RemoteInputSettings(host.settings),
    );
    await control.start();
    notifier = FakeNotifier();
    reveals = 0;
    notices = ControlNotices(
      host: control,
      notifier: notifier,
      l10n: lookupRemoteInputLocalizations(const Locale('en')),
      reveal: () async => reveals++,
    )..start();
  });

  tearDown(() => notices.dispose());

  test('a request shows the question with three answers', () async {
    await control.onRequest(pixel, ControlRequest(version: 1));
    await settle();

    final notice = notifier.shown[ControlNotices.consentNotice];
    expect(notice?.title, 'Let Pixel control this computer?');
    expect(notice?.category, ControlNotices.consentNotice);
    expect(
      ControlNotices.categories(
        lookupRemoteInputLocalizations(const Locale('en')),
      ).first.actions.map((action) => action.label),
      ['Always', 'Allow once', "Don't allow"],
    );
  });

  test('Always on the notice grants, and the indicator replaces it', () async {
    await control.onRequest(pixel, ControlRequest(version: 1));
    await settle();

    notifier.respond(ControlNotices.consentNotice, ControlNotices.alwaysAction);
    await settle();

    expect(control.active?.always, isTrue);
    expect(notifier.shown.keys, [ControlNotices.activeNotice]);
    expect(
      notifier.shown[ControlNotices.activeNotice]?.title,
      'Controlled by Pixel',
    );
  });

  test('Stop on the indicator cuts control off and removes it', () async {
    await control.onRequest(pixel, ControlRequest(version: 1));
    await control.answer(.allowOnce);
    await settle();

    notifier.respond(ControlNotices.activeNotice, ControlNotices.stopAction);
    await settle();

    expect(control.active, isNull);
    expect(notifier.shown, isEmpty);
    expect(notifier.cancelled, contains(ControlNotices.activeNotice));
  });

  test('a missing permission shows a fix, and tapping it reveals', () async {
    injector.statusNow = const .needsPermission(.quartz);
    await control.onRequest(pixel, ControlRequest(version: 1));
    await settle();

    expect(notifier.shown.keys, [ControlNotices.permissionNotice]);

    notifier.respond(ControlNotices.permissionNotice);
    await settle();
    expect(reveals, 1);

    notifier.respond(
      ControlNotices.permissionNotice,
      ControlNotices.openSettingsAction,
    );
    await settle();
    expect(injector.requests, 1);
  });

  test("Don't allow on the notice denies", () async {
    await control.onRequest(pixel, ControlRequest(version: 1));
    await settle();

    notifier.respond(ControlNotices.consentNotice, ControlNotices.denyAction);
    await settle();

    expect(control.pending, isNull);
    expect(notifier.shown, isEmpty);
    expect(pixel.sentOf<ControlDeny>(), hasLength(1));
  });
}
