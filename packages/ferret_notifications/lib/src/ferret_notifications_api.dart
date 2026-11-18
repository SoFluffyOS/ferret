import 'dart:async';

import 'package:ferret_notifications/src/messages.g.dart';
import 'package:ferret_notifications/src/notification_event.dart';
import 'package:flutter/foundation.dart';

/// Other apps' notifications on Android: read them as they are posted, run
/// their actions, dismiss them, and manage notification access.
///
/// Only Android implements it; check [isSupported] first.
class FerretNotifications {
  FerretNotifications({NotificationsHostApi? hostApi})
    : _hostApi = hostApi ?? NotificationsHostApi();

  /// The class name of the Android notification listener service. Pair it
  /// with the app's package name to get its component, such as for
  /// `MediaSessionManager.getActiveSessions`.
  static const listenerClassName =
      'io.sofluffy.ferret_notifications.FerretNotificationListener';

  final NotificationsHostApi _hostApi;

  // One handler per Flutter engine receives the platform's events, so every
  // instance shares it.
  static final StreamController<NotificationEvent> _events = .broadcast(
    onListen: () => NotificationsFlutterApi.setUp(_EventRelay(_events)),
    onCancel: () => NotificationsFlutterApi.setUp(null),
  );

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Notifications posted or removed from now on. Never replays the ones
  /// already showing.
  Stream<NotificationEvent> get events => _events.stream;

  Future<bool> isAccessGranted() => _hostApi.isAccessGranted();

  Future<bool> mayBeRestricted() => _hostApi.mayBeRestricted();

  Future<void> openAccessSettings() => _hostApi.openAccessSettings();

  Future<void> openAppInfo() => _hostApi.openAppInfo();

  Future<bool> isDeviceInUse() => _hostApi.isDeviceInUse();

  Future<List<PlatformApp>> listApps() => _hostApi.listApps();

  Future<bool> invokeAction(String key, String actionId, {String? replyText}) =>
      _hostApi.invokeAction(key, actionId, replyText);

  Future<bool> cancel(String key) => _hostApi.cancel(key);
}

class _EventRelay implements NotificationsFlutterApi {
  _EventRelay(this._sink);

  final StreamController<NotificationEvent> _sink;

  @override
  void onPosted(PlatformNotification notification) =>
      _sink.add(NotificationPostedEvent(notification));

  @override
  void onRemoved(String key) => _sink.add(NotificationRemovedEvent(key));

  @override
  void onListenerChanged(bool connected) =>
      _sink.add(ListenerChangedEvent(connected: connected));
}
