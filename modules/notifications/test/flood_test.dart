import 'dart:math';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/l10n/generated/notifications_localizations_en.dart';
import 'package:notifications/notifications.dart';

import 'support/fakes.dart';

/// Five busy group chats, bank codes, a delivery, shop promos, mail with its
/// "Checking for new messages", a download and music: about 300 notifications
/// in five minutes from eight apps, from a fake listener through two real
/// engines on loopback to the computer's inbox and its notices.
void main() {
  late Bus bus;
  final engines = <FerretEngine>[];

  setUp(() => bus = Bus());

  tearDown(() async {
    for (final engine in engines) {
      await engine.stop();
    }

    engines.clear();
  });

  Future<FerretEngine> startEngine(
    String name,
    NotificationsFeature feature, {
    MemorySettingsStore? settings,
  }) async {
    final engine = await FerretEngine.create(
      secrets: MemorySecretStore(),
      settings: settings ?? MemorySettingsStore(),
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

  test('300 notifications in five minutes from eight apps', () async {
    final source = FakeNotificationSource();
    final phoneFeature = NotificationsFeature(source: source);
    final laptopFeature = NotificationsFeature();
    final events = <MirrorEvent>[];
    laptopFeature.mirrorEvents.listen(events.add);

    final phone = await startEngine(
      'Pixel 7',
      phoneFeature,
      settings: MemorySettingsStore({MirrorPreferences.enabledKey: true}),
    );
    final laptop = await startEngine('Laptop', laptopFeature);
    final handle = await laptop.createPairingOffer();
    final offer = PairingCodes.parseOffer(handle.qrText)!
      ..hosts.clear()
      ..hosts.add('127.0.0.1');
    expect(await phone.pairWithOffer(offer), isA<Paired>());
    await until(() => events.whereType<MirrorCaughtUp>().isNotEmpty);

    final notifier = FakeNotifier();
    final inbox = InboxViewModel(
      feature: laptopFeature,
      notifier: notifier,
      deviceName: (_) => 'Pixel 7',
      strings: NotificationsLocalizationsEn.new,
    );
    addTearDown(inbox.dispose);

    final traffic = _Traffic(
      startMs: DateTime.now().millisecondsSinceEpoch + 1000,
    );
    final script = traffic.fiveMinutes();
    for (final event in script) {
      switch (event) {
        case NotificationPostedEvent(:final notification):
          source.post(notification);
        case NotificationRemovedEvent(:final key):
          source.remove(key);
        case ListenerChangedEvent():
          break;
      }
    }

    final forwarded = traffic.forwardedCount;
    await until(
      () => events.whereType<MirrorPosted>().length >= forwarded,
      timeout: const Duration(seconds: 20),
    );
    await pumpEventQueue();

    final posts = script.whereType<NotificationPostedEvent>().length;
    final shows = notifier.history.length;
    final sounds = notifier.history.where((notice) => !notice.silent).length;
    final distinct = {for (final notice in notifier.history) notice.id}.length;
    final kept = inbox.byDevice.values.fold(
      0,
      (sum, items) => sum + items.length,
    );
    final apps = {
      for (final event in script.whereType<NotificationPostedEvent>())
        event.notification.packageName,
    };
    // ignore: avoid_print
    print(
      'flood: ${script.length} events ($posts posts, ${apps.length} apps), '
      '${events.whereType<MirrorPosted>().length} reached the computer, '
      '$shows notice shows, $sounds with sound, $distinct distinct notices, '
      '${notifier.shown.length} left in the notification centre, '
      '$kept kept in the inbox',
    );

    // Before the budget (round #37): 229 shows, 67 with sound.
    expect(events.whereType<MirrorPosted>(), hasLength(forwarded));
    expect(shows, lessThanOrEqualTo(60));
    expect(sounds, lessThanOrEqualTo(25));
    final quiet = notifier.shown.values.singleWhere(
      (notice) => notice.id.endsWith('/quiet'),
    );
    expect(quiet.silent, isTrue);
    expect(quiet.title, 'Pixel 7');
    expect(quiet.body, contains('more apps. Kept quiet in Ferret.'));
    expect(notifier.shown.length, lessThanOrEqualTo(kept + 1));
    expect(apps.length, greaterThanOrEqualTo(8));
    expect(script.length, inInclusiveRange(300, 340));
    expect(kept, lessThanOrEqualTo(InboxViewModel.keptPerDevice));
    for (final key in notifier.shown.keys) {
      if (key.endsWith('/quiet')) {
        continue;
      }

      expect(
        inbox.byDevice.values
            .expand((items) => items)
            .any(
              (item) => key.endsWith('/${item.key}'),
            ),
        isTrue,
        reason: 'every notice left on screen still answers Reply/Dismiss',
      );
    }
  });
}

class _Traffic {
  _Traffic({required this.startMs});

  final int startMs;
  final _random = Random(37);

  /// Notifications the phone should send on, after its own filters.
  int forwardedCount = 0;

  static const _whatsApp = ('com.whatsapp', 'WhatsApp');
  static const _telegram = ('org.telegram.messenger', 'Telegram');
  static const _messenger = ('com.facebook.orca', 'Messenger');
  static const _zalo = ('com.zing.zalo', 'Zalo');
  static const _bank = ('com.VCB', 'VCB Digibank');
  static const _grab = ('com.grabtaxi.passenger', 'Grab');
  static const _shopee = ('com.shopee.vn', 'Shopee');
  static const _gmail = ('com.google.android.gm', 'Gmail');

  static const _groups = [
    (_whatsApp, 'Gia đình 👨‍👩‍👧', 'wa:family'),
    (_whatsApp, 'Work · Sprint 42', 'wa:work'),
    (_telegram, 'Flutter Devs VN', 'tg:devs'),
    (_messenger, 'Lớp 12A1 🎓', 'fb:class'),
    (_zalo, 'Hội hàng xóm', 'zl:neighbours'),
  ];

  final Map<String, int> _unread = {};
  final Map<String, int> _sentHash = {};

  List<NotificationEvent> fiveMinutes() {
    final events = <NotificationEvent>[];
    for (var second = 0; second < 300; second++) {
      final at = startMs + second * 1000;
      final roll = _random.nextInt(100);
      switch (roll) {
        case < 62:
          final (app, name, key) = _groups[_random.nextInt(_groups.length)];
          final count = _unread[key] = (_unread[key] ?? 0) + 1;
          events.add(
            _post(
              app,
              key: key,
              title: count == 1 ? name : '$name ($count tin nhắn)',
              text: 'Minh: tin số $count 😂 ok mọi người',
              at: at,
              conversation: true,
            ),
          );
          if (_random.nextInt(12) == 0) {
            _unread.remove(key);
            events.add(NotificationRemovedEvent(key));
            _sentHash.remove(key);
          }
        case < 64:
          events.add(
            _post(
              _bank,
              key: 'bank:$second',
              title: 'VCB',
              text: 'Ma OTP cua quy khach la ${100000 + second}. Code 5 phut.',
              at: at,
            ),
          );
        case < 72:
          events.add(
            _post(
              _grab,
              key: 'grab:order',
              title: 'Tài xế đang đến',
              text: 'Còn ${(300 - second) ~/ 30} phút',
              at: at,
            ),
          );
        case < 78:
          events.add(
            _post(
              _shopee,
              key: 'shopee:$second',
              title: '⚡ Flash sale',
              text: 'Giảm 50% chỉ hôm nay',
              at: at,
            ),
          );
        case < 86:
          events.add(
            _post(
              _gmail,
              key: 'gm:sync',
              title: 'Checking for new messages',
              text: '',
              at: at,
              importance: 1,
            ),
          );
        case < 90:
          events.add(
            _post(
              _gmail,
              key: 'gm:$second',
              title: 'Lan Nguyen',
              text: 'Re: Q4 plan',
              at: at,
            ),
          );
        case < 96:
          events.add(
            _post(
              _telegram,
              key: 'tg:download',
              title: 'Downloading video.mp4',
              text: '${second % 100}%',
              at: at,
              ongoing: true,
            ),
          );
        default:
          events.add(
            _post(
              ('com.spotify.music', 'Spotify'),
              key: 'spotify',
              title: 'Now playing',
              text: 'Song $second',
              at: at,
              media: true,
            ),
          );
      }
    }

    return events;
  }

  NotificationPostedEvent _post(
    (String, String) app, {
    required String key,
    required String title,
    required String text,
    required int at,
    bool conversation = false,
    bool ongoing = false,
    bool media = false,
    int importance = 4,
  }) {
    final notification = phoneNotification(
      key: key,
      packageName: app.$1,
      appName: app.$2,
      title: title,
      text: text,
      postedAtMs: at,
      isOngoing: ongoing,
      isMedia: media,
      importance: importance,
      replyable: conversation,
    );
    final quiet = ongoing || media || importance < 3;
    final hash = ForwardPolicy.contentHash(notification);
    if (!quiet && _sentHash[key] != hash) {
      _sentHash[key] = hash;
      forwardedCount++;
    }

    return NotificationPostedEvent(notification);
  }
}
