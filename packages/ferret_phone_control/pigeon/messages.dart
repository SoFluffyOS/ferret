import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_phone_control',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/io/sofluffy/ferret_phone_control/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.sofluffy.ferret_phone_control'),
  ),
)
/// What a finger does.
enum ServiceTouch { down, move, up, cancel }

/// The keys the service can stand in for. It can't press keys: each one is
/// an action on the focused text field, or on the system.
enum ServiceKey {
  enter,
  backspace,
  delete,
  tab,
  escape,
  arrowLeft,
  arrowRight,
  home,
  end,
  selectAll,
  copy,
  cut,
  paste,
  playPause,
  next,
  previous,
  volumeUp,
  volumeDown,
  volumeMute,
}

enum ServiceButton {
  back,
  home,
  recents,
  notifications,
  lockScreen,
  volumeUp,
  volumeDown,
}

/// The accessibility service that taps and types on the phone. Every call
/// but [isEnabled], [openSettings] and [setArmed] is refused unless armed.
@HostApi()
abstract class ControlServiceHostApi {
  /// The owner turned the service on in the system settings and it runs.
  bool isEnabled();

  /// Opens the system's Accessibility settings. False when they can't be
  /// opened.
  bool openSettings();

  /// Lets the service act, or stops it. Disarming lifts a finger that was
  /// left down.
  void setArmed(bool armed);

  /// [x] and [y] are fractions of the screen as it is turned right now.
  bool touch(ServiceTouch action, double x, double y);

  /// Wheel notches at ([x], [y]): positive [horizontal] is right, positive
  /// [vertical] is down.
  bool scroll(double x, double y, double horizontal, double vertical);

  /// Puts [text] at the cursor of the focused text field. False when
  /// nothing that takes text has the focus.
  bool typeText(String text);

  bool pressKey(ServiceKey key);

  bool pressButton(ServiceButton button);
}

@FlutterApi()
abstract class ControlServiceFlutterApi {
  /// The service was turned on or off in the system settings.
  void onEnabledChanged(bool enabled);
}
