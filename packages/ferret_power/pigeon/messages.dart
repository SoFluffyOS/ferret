import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_power',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/io/sofluffy/ferret_power/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_power'),
  ),
)
/// The app that manages root on this phone, when one is installed.
enum PlatformRootManager { none, magisk, kernelSu, aPatch, unknown }

/// What runs a capability: the Shizuku service, or `su`.
enum PlatformPowerBackend { shizuku, root }

/// A setting Ferret may turn on for itself through a backend.
enum PlatformPowerGrant { notificationAccess, batteryUnrestricted }

/// What a finger does in an injected touch.
enum PlatformTouchAction { down, move, up, cancel }

/// What this phone offers right now. Reading it never asks for anything.
class PlatformPowerState {
  PlatformPowerState({
    required this.shizukuInstalled,
    required this.shizukuRunning,
    required this.shizukuGranted,
    required this.rootFound,
    required this.rootGranted,
    required this.rootManager,
    required this.notificationAccess,
    required this.messagesAndCalls,
    required this.batteryUnrestricted,
  });

  bool shizukuInstalled;
  bool shizukuRunning;
  bool shizukuGranted;

  /// A `su` binary or a root manager app is present.
  bool rootFound;

  /// `su` answered as root since the app started.
  bool rootGranted;
  PlatformRootManager rootManager;

  /// Ferret's notification listener is turned on.
  bool notificationAccess;

  /// The SMS or the phone permission is granted.
  bool messagesAndCalls;

  /// Ferret is exempt from battery optimisation.
  bool batteryUnrestricted;
}

/// Text on the clipboard, read through a backend.
class PlatformPowerClip {
  PlatformPowerClip({required this.text, required this.sensitive});

  String text;

  /// The source app marked it as private (`EXTRA_IS_SENSITIVE`).
  bool sensitive;
}

@HostApi()
abstract class PowerHostApi {
  PlatformPowerState getState();

  /// Shows Shizuku's permission dialog. False when the user said no or
  /// Shizuku isn't running.
  @async
  bool requestShizukuPermission();

  /// Opens the Shizuku app. False when it isn't installed.
  bool openShizuku();

  bool openNotificationAccessSettings();

  /// Opens Ferret's page in the system settings.
  bool openAppSettings();

  /// Runs `su -c id`, which makes the root manager ask the user. False when
  /// denied or when there is no `su`.
  @async
  bool requestRoot();

  /// The clipboard text, read as the shell user. Null when it is empty or
  /// holds something other than text.
  @async
  PlatformPowerClip? readClipboard(PlatformPowerBackend backend);

  /// Starts reporting copies through
  /// [PowerFlutterApi.onClipboardChanged], also while Ferret is in the
  /// background.
  @async
  void startClipboardWatch(PlatformPowerBackend backend);

  @async
  void stopClipboardWatch();

  /// Turns [grant] on for Ferret itself. False when the command failed.
  @async
  bool grant(PlatformPowerBackend backend, PlatformPowerGrant grant);

  /// Injects a touch as the shell user. [x] and [y] are fractions of the
  /// screen as it is turned right now. False when the system refused.
  @async
  bool injectTouch(
    PlatformPowerBackend backend,
    PlatformTouchAction action,
    double x,
    double y,
  );

  /// Scrolls what is under ([x], [y]) by wheel notches: positive
  /// [horizontal] is right, positive [vertical] is up.
  @async
  bool injectScroll(
    PlatformPowerBackend backend,
    double x,
    double y,
    double horizontal,
    double vertical,
  );

  /// Presses or releases the Android key [keyCode] with [metaState] held.
  @async
  bool injectKey(
    PlatformPowerBackend backend,
    int keyCode,
    bool down,
    int metaState,
  );

  /// Types [text]. False when a character has no key on the phone's
  /// virtual keyboard; the others are still typed.
  @async
  bool injectText(PlatformPowerBackend backend, String text);

  /// Lifts a finger that was left down, and lets the root helper go.
  @async
  void releaseInput();
}

@FlutterApi()
abstract class PowerFlutterApi {
  /// Shizuku started, stopped, or its permission changed.
  void onStateChanged(PlatformPowerState state);

  void onClipboardChanged(PlatformPowerClip clip);

  /// The watcher ended on its own, such as when Shizuku stopped.
  void onClipboardWatchStopped();
}
