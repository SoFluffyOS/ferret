import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/l10n/generated/notifications_localizations_en.dart';
import 'package:notifications/notifications.dart';

import 'support/fakes.dart';

void main() {
  late FakeMirrorControl control;
  late FakeNotifier notifier;
  late InboxViewModel inbox;

  setUp(() {
    control = FakeMirrorControl();
    notifier = FakeNotifier();
    inbox = InboxViewModel(
      feature: control,
      notifier: notifier,
      deviceName: (deviceId) => 'Pixel',
      strings: NotificationsLocalizationsEn.new,
    );
  });

  tearDown(() => inbox.dispose());

  test('a replyable notification shows with Reply and Dismiss', () {
    control.emit(MirrorPosted('phone', mirrored()));

    final notice = notifier.shown.values.single;
    expect(notice.channel, NoticeChannel.incoming);
    expect(notice.category, InboxViewModel.messageCategory);
    expect(notice.groupKey, 'notifications/phone');
    expect(notice.title, 'Alex');
    expect(notice.silent, isFalse);
    expect(inbox.byDevice['phone']?.single.key, 'k1');
  });

  test('a held-back code says so instead of an empty line', () {
    final code = MirroredNotification(
      deviceId: 'phone',
      key: 'bank',
      appPackage: 'com.bank',
      appName: 'Bank',
      title: 'Your bank',
      text: '',
      postedAt: DateTime(2026, 11, 19),
      isConversation: false,
      textHidden: true,
    );
    control.emit(MirrorPosted('phone', code));

    expect(
      notifier.shown.values.single.body,
      'Code hidden. Open it on the phone.',
    );
    expect(inbox.byDevice['phone']?.single.text, startsWith('Code hidden'));
  });

  test('a notification without reply only offers Dismiss', () {
    control.emit(MirrorPosted('phone', mirrored(replyable: false)));

    expect(notifier.shown.values.single.category, InboxViewModel.alertCategory);
  });

  test('an update replaces the notice quietly', () {
    control
      ..emit(MirrorPosted('phone', mirrored()))
      ..emit(MirrorPosted('phone', mirrored(title: 'Alex (2)')));

    expect(notifier.shown, hasLength(1));
    expect(notifier.shown.values.single.title, 'Alex (2)');
    expect(notifier.shown.values.single.silent, isTrue);
    expect(inbox.byDevice['phone'], hasLength(1));
  });

  test('two phones get separate groups', () {
    control
      ..emit(MirrorPosted('phone', mirrored()))
      ..emit(MirrorPosted('tablet', mirrored(deviceId: 'tablet')));

    expect(notifier.shown.values.map((notice) => notice.groupKey).toSet(), {
      'notifications/phone',
      'notifications/tablet',
    });
  });

  test('a removal on the phone clears the notice here', () {
    control
      ..emit(MirrorPosted('phone', mirrored()))
      ..emit(const MirrorRemoved('phone', 'k1'));

    expect(notifier.shown, isEmpty);
    expect(inbox.isEmpty, isTrue);
  });

  test('a catch-up shows one summary and drops stale notifications', () {
    control
      ..emit(MirrorPosted('phone', mirrored()))
      ..emit(MirrorPosted('phone', mirrored(key: 'k2')))
      ..emit(
        const MirrorCaughtUp(
          'phone',
          missedCount: 6,
          activeKeys: {'k2'},
          missedAppNames: ['Signal', 'WhatsApp'],
        ),
      );

    final summaries = notifier.history.where(
      (notice) => notice.id.endsWith('/catch-up'),
    );
    expect(summaries, hasLength(1));
    expect(summaries.single.title, 'Pixel');
    expect(
      summaries.single.body,
      '6 notifications while away, from Signal, WhatsApp',
    );
    expect(inbox.byDevice['phone']?.map((item) => item.key), ['k2']);
    expect(notifier.cancelled, contains('notifications/phone/k1'));
  });

  test('a catch-up with nothing missed shows nothing', () {
    control.emit(
      const MirrorCaughtUp(
        'phone',
        missedCount: 0,
        activeKeys: {},
        missedAppNames: [],
      ),
    );

    expect(notifier.history, isEmpty);
  });

  test('Dismiss on a notice dismisses on the phone', () async {
    control.emit(MirrorPosted('phone', mirrored()));

    notifier.respond(
      const NoticeResponse(
        noticeId: 'notifications/phone/k1',
        actionId: InboxViewModel.dismissActionId,
      ),
    );
    await pumpEventQueue();

    expect(control.dismissed, [('phone', 'k1')]);
    expect(notifier.shown, isEmpty);
  });

  test('Reply sends the text to the reply action', () async {
    control.emit(MirrorPosted('phone', mirrored()));

    notifier.respond(
      const NoticeResponse(
        noticeId: 'notifications/phone/k1',
        actionId: InboxViewModel.replyActionId,
        replyText: 'On my way',
      ),
    );
    await pumpEventQueue();

    expect(control.invoked, [('phone', 'k1', '0', 'On my way')]);
  });

  test('Reply from a notice with no text field (Linux) opens the inbox to '
      'answer there', () async {
    final opened = <String>[];
    inbox.dispose();
    inbox = InboxViewModel(
      feature: control,
      notifier: notifier,
      deviceName: (deviceId) => 'Pixel',
      strings: NotificationsLocalizationsEn.new,
      onOpen: opened.add,
    );
    control.emit(MirrorPosted('phone', mirrored()));

    notifier.respond(
      const NoticeResponse(
        noticeId: 'notifications/phone/k1',
        actionId: InboxViewModel.replyActionId,
      ),
    );
    await pumpEventQueue();

    expect(opened, ['phone']);
    expect(control.invoked, isEmpty);
  });

  test('a reply that fails says so', () async {
    control
      ..actionResult = false
      ..emit(MirrorPosted('phone', mirrored()));

    notifier.respond(
      const NoticeResponse(
        noticeId: 'notifications/phone/k1',
        actionId: InboxViewModel.replyActionId,
        replyText: 'On my way',
      ),
    );
    await pumpEventQueue();

    final problem = notifier.history.last;
    expect(problem.channel, NoticeChannel.problems);
    expect(problem.title, 'Reply not sent');
  });

  test('responses to other features are ignored', () async {
    control.emit(MirrorPosted('phone', mirrored()));

    notifier.respond(
      const NoticeResponse(noticeId: 'drop/1', actionId: 'dismiss'),
    );
    await pumpEventQueue();

    expect(control.dismissed, isEmpty);
  });

  test('clear all empties this computer only', () async {
    control
      ..emit(MirrorPosted('phone', mirrored()))
      ..emit(MirrorPosted('phone', mirrored(key: 'k2')));

    await inbox.clearAll();

    expect(inbox.isEmpty, isTrue);
    expect(notifier.shown, isEmpty);
    expect(control.dismissed, isEmpty);
  });

  test('a removed phone takes its notifications along', () async {
    control
      ..emit(MirrorPosted('phone', mirrored()))
      ..emit(MirrorPosted('tablet', mirrored(deviceId: 'tablet')));

    await inbox.keepOnly({'tablet'});

    expect(inbox.byDevice.keys, ['tablet']);
    expect(notifier.cancelled, contains('notifications/phone/k1'));
    expect(notifier.cancelled, isNot(contains('notifications/tablet/k1')));
  });

  group('a burst', () {
    final start = DateTime(2026, 11, 23, 9);

    void post(int index, {String app = 'Zalo', int seconds = 0}) =>
        control.emit(
          MirrorPosted(
            'phone',
            mirrored(
              key: '$app/$index',
              appPackage: 'pkg.$app',
              appName: app,
              postedAt: start.add(Duration(seconds: seconds)),
            ),
          ),
        );

    List<LocalNotice> ownNotices() => [
      for (final notice in notifier.history)
        if (!notice.id.endsWith('/quiet')) notice,
    ];

    test('one app shows three a minute, the rest wait quietly', () {
      for (var index = 0; index < 10; index++) {
        post(index, seconds: index);
      }

      expect(ownNotices(), hasLength(3));
      expect(inbox.byDevice['phone'], hasLength(10));
      final quiet = notifier.shown['notifications/phone/quiet'];
      expect(quiet?.title, 'Pixel');
      expect(
        quiet?.body,
        'More from Zalo. Kept quiet in Ferret.',
      );
      expect(quiet?.silent, isTrue);
      expect(
        notifier.history.where((n) => n.id.endsWith('/quiet')),
        hasLength(1),
      );
    });

    test('a minute later the app may show again', () {
      for (var index = 0; index < 4; index++) {
        post(index, seconds: index);
      }

      post(4, seconds: 61);

      expect(ownNotices(), hasLength(4));
    });

    test('one phone shows six a minute across its apps', () {
      for (final (index, app) in [
        'Zalo',
        'Telegram',
        'Messenger',
        'WhatsApp',
      ].indexed) {
        post(0, app: app, seconds: index);
        post(1, app: app, seconds: index);
      }

      expect(ownNotices(), hasLength(6));
      final quiet = notifier.shown['notifications/phone/quiet'];
      expect(quiet?.body, 'More from WhatsApp. Kept quiet in Ferret.');
    });

    test('the quiet notice opens the list and starts the count again', () {
      final opened = <String>[];
      inbox.dispose();
      inbox = InboxViewModel(
        feature: control,
        notifier: notifier,
        deviceName: (deviceId) => 'Pixel',
        strings: NotificationsLocalizationsEn.new,
        onOpen: opened.add,
      );
      for (var index = 0; index < 5; index++) {
        post(index, seconds: index);
      }

      notifier.respond(
        const NoticeResponse(noticeId: 'notifications/phone/quiet'),
      );
      post(5, seconds: 70);
      post(6, seconds: 71);
      post(7, seconds: 72);
      post(8, seconds: 73);

      expect(opened, ['phone']);
      expect(
        notifier.history.where((n) => n.id.endsWith('/quiet')),
        hasLength(2),
      );
    });

    test('a one-time code always shows', () {
      for (var index = 0; index < 3; index++) {
        post(index, app: 'Bank', seconds: index);
      }

      control.emit(
        MirrorPosted(
          'phone',
          mirrored(
            key: 'Bank/code',
            appPackage: 'pkg.Bank',
            appName: 'Bank',
            postedAt: start.add(const Duration(seconds: 4)),
            textHidden: true,
          ),
        ),
      );

      expect(ownNotices(), hasLength(4));
    });
  });

  test('a notification pushed out of the list takes its notice along', () {
    for (var index = 0; index <= InboxViewModel.keptPerDevice; index++) {
      control.emit(
        MirrorPosted(
          'phone',
          mirrored(
            key: 'k$index',
            postedAt: DateTime(2026, 11, 23).add(Duration(minutes: index)),
          ),
        ),
      );
    }

    expect(notifier.cancelled, contains('notifications/phone/k0'));
    expect(notifier.shown, isNot(contains('notifications/phone/k0')));
  });
}
