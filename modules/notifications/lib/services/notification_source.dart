import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:notifications/services/notification_access.dart';

/// Where a device reads its own notifications from. Only Android has one.
abstract interface class NotificationSource {
  /// Notifications posted or removed from now on.
  Stream<NotificationEvent> get events;

  Future<bool> isAccessGranted();

  /// The screen is on and unlocked.
  Future<bool> isDeviceInUse();

  Future<List<PlatformApp>> listApps();

  Future<bool> invokeAction(String key, String actionId, {String? replyText});

  Future<bool> cancel(String key);
}

/// A [NotificationSource] backed by the Android notification listener.
class PlatformNotificationSource
    implements NotificationSource, NotificationAccess {
  PlatformNotificationSource([FerretNotifications? platform])
    : _platform = platform ?? FerretNotifications();

  final FerretNotifications _platform;

  @override
  Stream<NotificationEvent> get events => _platform.events;

  @override
  Future<bool> isAccessGranted() => _platform.isAccessGranted();

  @override
  Future<bool> mayBeRestricted() => _platform.mayBeRestricted();

  @override
  Future<void> openAccessSettings() => _platform.openAccessSettings();

  @override
  Future<void> openAppInfo() => _platform.openAppInfo();

  @override
  Future<bool> isDeviceInUse() => _platform.isDeviceInUse();

  @override
  Future<List<PlatformApp>> listApps() => _platform.listApps();

  @override
  Future<bool> invokeAction(String key, String actionId, {String? replyText}) =>
      _platform.invokeAction(key, actionId, replyText: replyText);

  @override
  Future<bool> cancel(String key) => _platform.cancel(key);
}
