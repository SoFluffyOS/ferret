import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:notifications/models/models.dart';
import 'package:notifications/services/mirror_preferences.dart';

/// Decides which phone notifications are worth showing on a computer.
abstract final class ForwardPolicy {
  /// Below `NotificationManager.IMPORTANCE_DEFAULT`: silent, minimized or
  /// blocked notifications.
  static const _quietBelow = 3;

  /// Android reports -1000 when it doesn't know the importance.
  static const _unknownImportance = -1000;

  /// Everything except whether the phone is in use, which needs the platform.
  static ForwardDecision decide(
    PlatformNotification notification,
    MirrorPreferences preferences,
  ) {
    if (!preferences.enabled) {
      return .disabled;
    }

    if (isNoise(notification)) {
      return .noise;
    }

    if (!preferences.isAllowed(notification.packageName)) {
      return .appNotAllowed;
    }

    return .forward;
  }

  /// Ongoing work, foreground services, quiet notifications, group summaries
  /// and empty ones never leave the phone.
  static bool isNoise(PlatformNotification notification) {
    final importance = notification.importance;
    final isQuiet =
        importance != _unknownImportance && importance < _quietBelow;
    final isEmpty =
        notification.title.trim().isEmpty && notification.text.trim().isEmpty;

    return notification.isOngoing ||
        notification.isForegroundService ||
        notification.isGroupSummary ||
        isQuiet ||
        isEmpty;
  }

  /// Changes when anything the receiver shows changes, so re-posts of the
  /// same content (such as a sort or a sound update) are dropped.
  static int contentHash(PlatformNotification notification) => Object.hashAll([
    notification.packageName,
    notification.appName,
    notification.title,
    notification.text,
    notification.isConversation,
    for (final action in notification.actions) ...[
      action.id,
      action.title,
      action.isReply,
    ],
  ]);
}
