import 'package:ferret_calls/src/messages.g.dart';

/// A phone's calls: what is ringing, what to do with it, and what happened
/// before. `FerretCalls` implements it on Android; tests use a fake.
abstract interface class PhoneCalls {
  /// Call state changes while monitoring, starting with the current state.
  Stream<PlatformPhoneEvent> get events;

  Future<PlatformCallPermissions> permissions();

  /// Shows the system's permission dialogs for what is missing.
  Future<PlatformCallPermissions> requestPermissions();

  /// Opens the app's page in system settings.
  Future<void> openAppSettings();

  /// False when the permission to see calls is missing.
  Future<bool> startMonitoring();

  Future<void> stopMonitoring();

  Future<PlatformCallResult> answer();

  /// Declines the ringing call or hangs up the ongoing one.
  Future<PlatformCallResult> end();

  Future<PlatformCallResult> silenceRinger();

  Future<PlatformCallResult> dial(String number);

  /// The newest [limit] calls, newest first.
  Future<List<PlatformCallLogEntry>> recentCalls(int limit);

  /// The contact with [number], or null.
  Future<PlatformContact?> lookupContact(String number);
}
