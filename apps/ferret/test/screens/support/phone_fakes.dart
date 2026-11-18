// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.

import 'dart:async';

import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:messages/messages.dart';
import 'package:notifications/notifications.dart';

/// An Android phone whose notification access is still off, so the
/// notifications feature offers its phone setup. Tests run on the macOS
/// host, where the real plugin says it isn't supported.
class OffNotificationSource implements NotificationSource, NotificationAccess {
  @override
  Stream<NotificationEvent> get events => const Stream.empty();

  @override
  Future<bool> isAccessGranted() async => false;

  @override
  Future<bool> mayBeRestricted() async => false;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> openAppInfo() async {}

  @override
  Future<bool> isDeviceInUse() async => false;

  @override
  Future<List<PlatformApp>> listApps() async => const [];

  @override
  Future<bool> invokeAction(
    String key,
    String actionId, {
    String? replyText,
  }) async => false;

  @override
  Future<bool> cancel(String key) async => false;
}

/// An Android phone with a SIM but no SMS permission yet, so the messages
/// feature offers its phone setup. Reading texts is never reached.
class OffSmsSource implements SmsSource {
  static const _off = SmsAccess(
    hasTelephony: true,
    canRead: false,
    canSend: false,
    canReadContacts: false,
  );

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<SmsAccess> access() async => _off;

  @override
  Future<SmsAccess> requestAccess() async => _off;

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<void> startWatching() async {}

  @override
  Future<void> stopWatching() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Screens never read texts.');
}
