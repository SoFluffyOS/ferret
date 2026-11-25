// A busy phone's notifications on a computer: five group chats in
// Vietnamese with emoji, a bank code, a delivery, shop promos and a line in
// Arabic, more than the list keeps. Rendered into temp/screens as
// `flood_<name>_<size>_<mode>.png`. Run from apps/ferret:
//
//   flutter test test/screens/notifications_flood_screens_test.dart
@Tags(['screens'])
library;

import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/notifications.dart';

import 'screens_test.dart' show phoneFeatures;
import 'support/phone_fakes.dart';
import 'support/screen_fonts.dart';
import 'support/screen_harness.dart';
import 'window_screens_test.dart' show appFeatures, windowSizes;

void main() {
  setUpAll(loadScreenFonts);

  for (final size in [popover, windowSizes.first, windowSizes[2]]) {
    for (final brightness in Brightness.values) {
      testWidgets('flood ${size.name} ${brightness.name}', (tester) async {
        setScreen(tester, size, brightness);
        mockPlugins(tester);
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final rig = await ScreenRig.create(
          tester,
          features: appFeatures(),
          tipsDone: true,
        );
        await rig.show(tester);

        final source = _FloodSource();
        final feature = NotificationsFeature(source: source);
        await rig.pairConnectedPhone(
          tester,
          phoneFeatures: [
            for (final ui in phoneFeatures())
              switch (ui.featureId) {
                NotificationsFeature.featureId =>
                  NotificationsFeatureUi.withFeature(feature, access: source),
                _ => ui,
              },
          ],
        );
        await tester.runAsync(() async {
          await feature.preferences.setEnabled(true);
          await Future<void>.delayed(const Duration(milliseconds: 300));
          _postFlood(source);
          await Future<void>.delayed(const Duration(seconds: 1));
        });
        await rig.settle(tester);
        await rig.tapText(tester, 'Notifications');
        await rig.capture(tester, 'flood_inbox', size, brightness);
        final reply = find.byIcon(LucideIcons.reply);
        if (reply.evaluate().isNotEmpty) {
          await tester.tap(reply.first);
          await tester.pump();
          await tester.enterText(find.byType(EditableText).last, 'Về liền 🏃');
          await rig.settle(tester);
          await rig.capture(tester, 'flood_reply', size, brightness);
        }
        await rig.dispose(tester);
      });
    }
  }
}

void _postFlood(_FloodSource source) {
  final start = DateTime.now().millisecondsSinceEpoch + 1000;
  const chats = [
    (
      'com.whatsapp',
      'WhatsApp',
      'Gia đình 👨‍👩‍👧',
      'Mẹ: Tối nay về ăn cơm nhé 🍲',
    ),
    ('com.whatsapp', 'WhatsApp', 'Work · Sprint 42', 'Lan: PR #812 is ready ✅'),
    (
      'org.telegram.messenger',
      'Telegram',
      'Flutter Devs VN',
      'An: Ai dùng Impeller chưa?',
    ),
    (
      'com.facebook.orca',
      'Messenger',
      'Lớp 12A1 🎓',
      'Hùng: họp lớp thứ Bảy nha 🎉',
    ),
    ('com.zing.zalo', 'Zalo', 'Hội hàng xóm', 'Cô Ba: mất nước từ 9h đến 11h'),
  ];
  for (var index = 0; index < 60; index++) {
    final (package, app, title, text) = chats[index % chats.length];
    source.post(
      PlatformNotification(
        key: '$package/${index % chats.length}',
        packageName: package,
        appName: app,
        title: '$title (${index ~/ chats.length + 1} tin nhắn)',
        text: text,
        postedAtMs: start + index * 1000,
        isConversation: true,
        isOngoing: false,
        isForegroundService: false,
        isGroupSummary: false,
        isMedia: false,
        importance: 4,
        actions: [
          PlatformNotificationAction(id: '0', title: 'Reply', isReply: true),
        ],
      ),
    );
    final extra = switch (index) {
      10 => (
        'com.VCB',
        'VCB Digibank',
        'VCB',
        'Ma OTP: 482913. Code het han sau 5 phut.',
      ),
      20 => (
        'com.grabtaxi.passenger',
        'Grab',
        'Tài xế đang đến',
        'Còn 3 phút · 59X1-234.56',
      ),
      30 => (
        'com.shopee.vn',
        'Shopee',
        '⚡ Flash sale 12.12',
        'Giảm 50% cho đơn đầu tiên hôm nay',
      ),
      40 => ('com.whatsapp', 'WhatsApp', 'Omar', 'مرحبا، هل أنت قادم الليلة؟'),
      _ => null,
    };
    if (extra case (final package, final app, final title, final text)) {
      source.post(
        PlatformNotification(
          key: '$package/extra$index',
          packageName: package,
          appName: app,
          title: title,
          text: text,
          postedAtMs: start + index * 1000 + 500,
          isConversation: false,
          isOngoing: false,
          isForegroundService: false,
          isGroupSummary: false,
          isMedia: false,
          importance: 4,
          actions: const [],
        ),
      );
    }
  }
}

/// A phone with notification access on whose notifications the test posts.
class _FloodSource extends OffNotificationSource {
  final StreamController<NotificationEvent> _events = .broadcast(sync: true);

  void post(PlatformNotification notification) =>
      _events.add(NotificationPostedEvent(notification));

  @override
  Stream<NotificationEvent> get events => _events.stream;

  @override
  Future<bool> isAccessGranted() async => true;
}
