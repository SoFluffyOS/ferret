import 'package:ferret_notifications/src/messages.g.dart';

/// Something that happened to another app's notification.
sealed class NotificationEvent {
  const NotificationEvent();
}

/// A notification was posted or updated.
final class NotificationPostedEvent extends NotificationEvent {
  const NotificationPostedEvent(this.notification);

  final PlatformNotification notification;
}

/// The notification with [key] is gone.
final class NotificationRemovedEvent extends NotificationEvent {
  const NotificationRemovedEvent(this.key);

  final String key;
}

/// The system connected or disconnected the listener, such as after the
/// person turned notification access on or off.
final class ListenerChangedEvent extends NotificationEvent {
  const ListenerChangedEvent({required this.connected});

  final bool connected;
}
