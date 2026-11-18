import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iphone/iphone.dart';
import 'package:iphone/l10n/l10n.dart';

import 'helpers/fakes.dart';

void main() {
  late Rig rig;
  late RecordingNotifier notifier;
  late IphoneNotices notices;
  var now = DateTime(2026, 11, 18, 12);

  Future<void> start({Map<String, Object?>? more}) async {
    now = DateTime(2026, 11, 18, 12);
    rig = await Rig.start(
      settings: pairedSettings(more),
      retryDelays: const [],
    );
    await settle();
    rig.iphone.apps['com.apple.MobileSMS'] = 'Messages';
    rig.iphone.apps['com.apple.mobilephone'] = 'Phone';
    notifier = RecordingNotifier();
    notices = IphoneNotices(
      feature: rig.feature,
      notifier: notifier,
      l10n: lookupIphoneLocalizations(const Locale('en')),
      clock: () => now,
    )..start();
    addTearDown(() async {
      notices.dispose();
      await rig.feature.stop();
    });
  }

  test(
    'shows a notification on the incoming channel, grouped by app',
    () async {
      await start();

      rig.iphone.notify(
        7,
        appId: 'com.apple.MobileSMS',
        title: 'Zoé',
        subtitle: 'Family',
        message: 'On my way',
      );
      await settle();

      final notice = notifier.shown['iphone.n.7'];
      expect(notice?.channel.name, 'incoming');
      expect(notice?.title, 'Messages: Zoé');
      expect(notice?.body, 'Family\nOn my way');
      expect(notice?.groupKey, 'iphone.com.apple.MobileSMS');
      expect(notice?.category, IphoneNotices.clearCategory);
      expect(notice?.silent, isFalse);
    },
  );

  test('uses the app name alone when there is no title', () async {
    await start();

    rig.iphone.notify(1, appId: 'com.apple.MobileSMS', message: 'Hello');
    await settle();

    expect(notifier.shown['iphone.n.1']?.title, 'Messages');
    expect(notifier.shown['iphone.n.1']?.body, 'Hello');
  });

  test('hides what it says when previews are off', () async {
    await start(more: {IphoneSettings.hidePreviewsKey: true});

    rig.iphone.notify(
      1,
      appId: 'com.apple.MobileSMS',
      title: 'Zoé',
      message: 'The code is 123456',
    );
    await settle();

    expect(notifier.shown['iphone.n.1']?.title, 'Messages');
    expect(notifier.shown['iphone.n.1']?.body, 'New notification');
  });

  test(
    'offers Answer and Decline on a call, Call back on a missed one',
    () async {
      await start();

      rig.iphone
        ..notify(
          1,
          appId: 'com.apple.mobilephone',
          title: 'Mum',
          category: .incomingCall,
          positive: true,
        )
        ..notify(
          2,
          appId: 'com.apple.mobilephone',
          title: 'Mum',
          category: .missedCall,
          positive: true,
        )
        ..notify(3, title: 'Invite', positive: true)
        ..notify(4, title: 'Only yes', positive: true, negative: false)
        ..notify(5, title: 'Nothing to do', negative: false);
      await settle();

      expect(
        notifier.shown['iphone.n.1']?.category,
        IphoneNotices.callCategory,
      );
      expect(
        notifier.shown['iphone.n.2']?.category,
        IphoneNotices.callBackCategory,
      );
      expect(
        notifier.shown['iphone.n.3']?.category,
        IphoneNotices.acceptOrClearCategory,
      );
      expect(
        notifier.shown['iphone.n.4']?.category,
        IphoneNotices.acceptCategory,
      );
      expect(notifier.shown['iphone.n.5']?.category, isNull);
    },
  );

  test('every category a notice uses is declared', () {
    final declared = IphoneNotices.categories(
      lookupIphoneLocalizations(const Locale('en')),
    ).map((category) => category.id);

    expect(declared, {
      IphoneNotices.clearCategory,
      IphoneNotices.callCategory,
      IphoneNotices.callBackCategory,
      IphoneNotices.acceptCategory,
      IphoneNotices.acceptOrClearCategory,
    });
    expect(declared.every((id) => id.startsWith('iphone.')), isTrue);
  });

  test('quiet ones and updates make no sound', () async {
    await start();

    rig.iphone.notify(1, title: 'Quiet', silent: true);
    await settle();
    rig.iphone.notify(2, title: 'First');
    await settle();
    rig.iphone.notify(2, title: 'Second', kind: .modified);
    await settle();

    expect(notifier.shown['iphone.n.1']?.silent, isTrue);
    expect(notifier.history.map((notice) => notice.silent), [
      true,
      false,
      true,
    ]);
    expect(notifier.shown['iphone.n.2']?.title.endsWith('Second'), isTrue);
  });

  test('a burst goes quiet after the first few, then recovers', () async {
    await start();

    for (var uid = 1; uid <= 8; uid++) {
      rig.iphone.notify(uid, title: 'Message $uid');
    }
    await settle();
    now = now.add(const Duration(seconds: 30));
    rig.iphone.notify(9, title: 'Later');
    await settle();

    expect(notifier.history.map((notice) => notice.silent), [
      false,
      false,
      false,
      false,
      true,
      true,
      true,
      true,
      false,
    ]);
  });

  test('takes a notice away when it goes on the iPhone', () async {
    await start();
    rig.iphone.notify(1, title: 'Hello');
    await settle();

    rig.iphone.remove(1);
    await settle();

    expect(notifier.shown, isEmpty);
    expect(notifier.cancelled, ['iphone.n.1']);
  });

  test('performs the action on the iPhone and clears the notice', () async {
    await start();
    rig.iphone
      ..notify(1, title: 'Hello')
      ..notify(2, title: 'Mum', category: .incomingCall, positive: true);
    await settle();

    notifier
      ..respond('iphone.n.1', actionId: IphoneNotices.negativeAction)
      ..respond('iphone.n.2', actionId: IphoneNotices.positiveAction);
    await settle();

    expect(rig.iphone.performed, [
      (1, AncsAction.negative),
      (2, AncsAction.positive),
    ]);
    expect(notifier.shown, isEmpty);
  });

  test('a plain click on the notice does nothing on the iPhone', () async {
    await start();
    rig.iphone.notify(1, title: 'Hello');
    await settle();

    notifier
      ..respond('iphone.n.1')
      ..respond('find.ringing', actionId: IphoneNotices.negativeAction);
    await settle();

    expect(rig.iphone.performed, isEmpty);
    expect(notifier.shown.keys, ['iphone.n.1']);
  });

  test('says so when an action does not reach the iPhone', () async {
    await start();
    rig.iphone.notify(1, title: 'Hello');
    await settle();
    rig.transport.writeError = const GattException(.notConnected);

    notifier.respond('iphone.n.1', actionId: IphoneNotices.negativeAction);
    await settle();

    final problem = notifier.shown[IphoneNotices.failedNoticeId];
    expect(problem?.channel.name, 'problems');
    expect(problem?.title, endsWith("didn't answer"));
    expect(notifier.shown.containsKey('iphone.n.1'), isTrue);
  });
}
