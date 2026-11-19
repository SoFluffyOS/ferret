import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_system',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/io/sofluffy/ferret_system/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_system'),
    swiftOut: 'macos/ferret_system/Sources/ferret_system/Messages.g.swift',
  ),
)
/// What changed about the network this device is on.
enum NetworkChange {
  /// A network came up, such as joining Wi-Fi.
  available,

  /// The network went away.
  lost,

  /// The same network got new addresses or a new router.
  changed,

  /// The device woke from sleep or the screen turned on.
  wake,
}

/// How a request to add the Quick Settings tile ended.
enum AddTileResult { added, alreadyAdded, notAdded, unsupported }

/// Something the user asked for from outside the app, such as the Quick
/// Settings tile or a notification action.
class SystemActionMessage {
  SystemActionMessage({required this.id, required this.data});

  String id;
  Map<String, String> data;
}

/// Whether Ferret is paused, and until when (null: until resumed).
class PauseMessage {
  PauseMessage({required this.paused, this.untilMs});

  bool paused;
  int? untilMs;
}

@HostApi()
abstract class SystemHostApi {
  /// Lets the app receive multicast packets (Android drops them otherwise).
  void acquireMulticastLock();

  void releaseMulticastLock();

  bool isMulticastLockHeld();

  /// Dart is ready: deliver actions queued while it started.
  void listenForActions();

  /// Starts or stops reporting [SystemFlutterApi.onNetworkChange].
  void setNetworkWatching(bool watching);

  /// Runs the foreground service that keeps Ferret alive in the background.
  void startService();

  void stopService();

  bool isServiceRunning();

  void setStartOnBoot(bool enabled);

  /// Names of the devices connected right now, for the notification and the
  /// Quick Settings tile.
  void updateStatus(List<String> connectedDevices);

  void setPause(PauseMessage pause);

  PauseMessage pauseState();

  bool isIgnoringBatteryOptimizations();

  /// Shows the system dialog that exempts Ferret from battery optimization.
  /// Returns false when nothing could be opened.
  bool requestIgnoreBatteryOptimizations();

  /// The device maker as Android reports it, such as `samsung`.
  String manufacturer();

  /// Opens the maker's own background or autostart settings, or the app's
  /// details page when there is none. Returns false when nothing opened.
  bool openMakerBatterySettings();

  /// Whether the user set Ferret's battery use to Restricted. Android then
  /// drops the service as soon as the app leaves the screen.
  bool isBackgroundRestricted();

  /// Opens Android's page for this app, where battery use is set. Returns
  /// false when nothing opened.
  bool openAppSettings();

  /// When Android stopped the service without being asked, in milliseconds
  /// since the epoch, over the last week.
  List<int> recentServiceStops();

  bool canRequestAddTile();

  @async
  AddTileResult requestAddTile();

  bool areNotificationsAllowed();

  @async
  bool requestNotificationPermission();

  /// Whether the person is at this computer: the screen is unlocked and
  /// this account is the one in front (not switched away from). Always true
  /// where there is no such thing.
  bool isScreenSessionActive();
}

@FlutterApi()
abstract class SystemFlutterApi {
  void onAction(SystemActionMessage action);

  void onNetworkChange(NetworkChange change);

  /// The user paused or resumed from the notification, or a pause ran out.
  void onPauseChanged(PauseMessage pause);

  /// The screen locked or unlocked, or another account took over the
  /// screen or gave it back.
  void onScreenSessionChanged(bool active);
}
