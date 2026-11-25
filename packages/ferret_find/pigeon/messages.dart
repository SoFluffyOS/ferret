import 'package:pigeon/pigeon.dart';

// Regenerate with `dart run pigeon --input pigeon/messages.dart` from the
// package folder. Windows and Linux are Dart only (lib/src/desktop_find.dart).
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_find',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/io/sofluffy/ferret_find/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_find'),
    swiftOut: [
      'ios/ferret_find/Sources/ferret_find/Messages.g.swift',
      'macos/ferret_find/Sources/ferret_find/Messages.g.swift',
    ],
  ),
)
/// The output volume as the platform sees it, to raise it and put it back.
class PlatformAudio {
  PlatformAudio({
    required this.volume,
    required this.maxVolume,
    required this.muted,
    required this.interruptionFilter,
    required this.quiet,
  });

  /// Android: the alarm stream's index. macOS: 0 to 100.
  int volume;
  int maxVolume;
  bool muted;

  /// Android's `NotificationManager` interruption filter; 0 when unknown or
  /// not Android.
  int interruptionFilter;

  /// The device is on silent, vibrate or Do Not Disturb. Read only.
  bool quiet;
}

/// What this device may and can do while ringing.
class PlatformRingAbilities {
  PlatformRingAbilities({
    required this.controlsVolume,
    required this.needsDndAccess,
    required this.dndAccessGranted,
    required this.fullScreenAllowed,
    required this.hasTorch,
    required this.ringsInBackground,
    required this.showsOwnAlert,
  });

  /// It can read, raise and restore the output volume.
  bool controlsVolume;

  /// Ringing through Do Not Disturb needs a permission (Android).
  bool needsDndAccess;
  bool dndAccessGranted;

  /// Android 14+ lets people deny full-screen notifications.
  bool fullScreenAllowed;
  bool hasTorch;

  /// False on iOS, which stops Ferret soon after it leaves the screen.
  bool ringsInBackground;

  /// The platform shows its own ringing notification with "Found it".
  bool showsOwnAlert;
}

/// Starts ringing: sound, vibration, torch and the platform notice.
class PlatformAlert {
  PlatformAlert({
    required this.title,
    required this.body,
    required this.foundItLabel,
    required this.silent,
    required this.vibrate,
    required this.flashTorch,
    required this.maxSeconds,
  });

  String title;
  String body;
  String foundItLabel;

  /// Vibrate and show the notice, but play no sound.
  bool silent;
  bool vibrate;
  bool flashTorch;

  /// Stops on its own after this long, even if Dart never asks.
  int maxSeconds;
}

@HostApi()
abstract class FindHostApi {
  PlatformRingAbilities abilities();

  /// Null when the platform can't read the volume.
  PlatformAudio? readAudio();

  /// Sets the volume, mute and Do Not Disturb filter from [audio].
  void applyAudio(PlatformAudio audio);

  void startAlert(PlatformAlert alert);

  void stopAlert();

  void openDndAccessSettings();

  void openFullScreenSettings();
}

@FlutterApi()
abstract class FindFlutterApi {
  /// The alert stopped on the device itself: `found` (Found it, or the
  /// notice was dismissed), `volume_key` or `timeout`.
  void onAlertStopped(String reason);
}
