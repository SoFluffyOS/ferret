import 'package:pigeon/pigeon.dart';

// Regenerate with `fvm dart run pigeon --input pigeon/messages.dart` from the
// package folder. Reading other apps' notifications is Android only.
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_notifications',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/io/sofluffy/ferret_notifications/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_notifications'),
  ),
)
/// A button on a notification.
class PlatformNotificationAction {
  PlatformNotificationAction({
    required this.id,
    required this.title,
    required this.isReply,
  });

  /// The action's index on the notification, as text.
  String id;
  String title;

  /// The action takes free-form text through a RemoteInput.
  bool isReply;
}

/// A notification another app posted.
class PlatformNotification {
  PlatformNotification({
    required this.key,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    required this.postedAtMs,
    required this.appIcon,
    required this.isConversation,
    required this.isOngoing,
    required this.isForegroundService,
    required this.isGroupSummary,
    required this.isMedia,
    required this.importance,
    required this.actions,
  });

  String key;
  String packageName;
  String appName;
  String title;
  String text;
  int postedAtMs;

  /// A small PNG of the app's icon, or null when it could not be drawn.
  Uint8List? appIcon;
  bool isConversation;
  bool isOngoing;
  bool isForegroundService;
  bool isGroupSummary;

  /// A media player's controls, such as a paused song.
  bool isMedia;

  /// The channel importance (`NotificationManager.IMPORTANCE_*`), or -1000
  /// when unknown.
  int importance;
  List<PlatformNotificationAction> actions;
}

/// An app a person can pick for mirroring.
class PlatformApp {
  PlatformApp({
    required this.packageName,
    required this.name,
    this.icon,
    this.lastPostedMs,
  });

  String packageName;
  String name;
  Uint8List? icon;

  /// When the app's newest notification still showing was posted, or null
  /// when it has none.
  int? lastPostedMs;
}

@HostApi()
abstract class NotificationsHostApi {
  /// Whether the person turned on notification access for this app.
  bool isAccessGranted();

  /// Whether Android 13+ probably blocks the access toggle because the app
  /// was installed from a file ("restricted settings"). Best effort.
  bool mayBeRestricted();

  /// Opens the notification access page for this app.
  void openAccessSettings();

  /// Opens this app's App info page, where "Allow restricted settings" is.
  void openAppInfo();

  /// The screen is on and unlocked.
  bool isDeviceInUse();

  /// Apps that have a launcher entry, sorted by name.
  @async
  List<PlatformApp> listApps();

  /// Runs action [actionId] of the notification [key], with [replyText] for a
  /// reply action. Returns false when the notification or action is gone.
  bool invokeAction(String key, String actionId, String? replyText);

  /// Dismisses the notification [key]. Returns false when the listener isn't
  /// connected.
  bool cancel(String key);
}

@FlutterApi()
abstract class NotificationsFlutterApi {
  void onPosted(PlatformNotification notification);

  void onRemoved(String key);

  /// The system connected or disconnected the listener service.
  void onListenerChanged(bool connected);
}
