import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/models/models.dart';

/// Notifications' lines in Home's Activity list on a computer: one per
/// phone that has notifications waiting.
abstract final class NotificationsActivity {
  /// One line per device in [byDevice], whose lists are newest first.
  /// [onOpen] opens the full list.
  static List<ActivityItem> items(
    NotificationsLocalizations l10n,
    Map<String, List<MirroredNotification>> byDevice, {
    required String Function(String deviceId) deviceName,
    required VoidCallback onOpen,
  }) => [
    for (final MapEntry(key: deviceId, value: notifications)
        in byDevice.entries)
      if (notifications case [final latest, ...])
        ActivityItem(
          id: deviceId,
          deviceId: deviceId,
          icon: LucideIcons.bell,
          title: switch (notifications.length) {
            1 => _single(l10n, latest),
            final count => l10n.activityCount(count, deviceName(deviceId)),
          },
          detail: switch (latest.text.isEmpty) {
            true => null,
            false => latest.text,
          },
          at: latest.postedAt,
          onTap: onOpen,
          private: PrivateContent(
            deviceId,
            cover: switch (notifications.length) {
              1 => l10n.privateCover(deviceName(deviceId)),
              final count => l10n.activityCount(count, deviceName(deviceId)),
            },
          ),
        ),
  ];

  static String _single(
    NotificationsLocalizations l10n,
    MirroredNotification notification,
  ) {
    if (notification.title.isEmpty) {
      return notification.appName;
    }

    if (notification.appName.isEmpty) {
      return notification.title;
    }

    return l10n.activityOne(notification.appName, notification.title);
  }
}
