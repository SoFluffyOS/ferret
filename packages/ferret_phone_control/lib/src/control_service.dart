import 'package:ferret_phone_control/src/messages.g.dart';

export 'package:ferret_phone_control/src/messages.g.dart'
    show ServiceButton, ServiceKey, ServiceTouch;

/// Ferret's accessibility service, as the app sees it. It refuses to act
/// unless armed.
abstract interface class ControlService {
  /// The owner turned it on in the system's Accessibility settings, and it
  /// runs.
  Future<bool> isEnabled();

  /// Fires when the owner turns it on or off.
  Stream<bool> get enabledChanges;

  /// Opens the system's Accessibility settings, on Ferret's row where
  /// Android allows it. False when they can't be opened.
  Future<bool> openSettings();

  /// Lets it act, or stops it and lifts a finger left down.
  Future<void> setArmed(bool armed);

  /// [x] and [y] are fractions of the screen as it is turned now.
  Future<bool> touch(ServiceTouch action, double x, double y);

  /// Wheel notches at ([x], [y]): positive [horizontal] is right, positive
  /// [vertical] is down.
  Future<bool> scroll(double x, double y, double horizontal, double vertical);

  /// Puts [text] at the cursor of the focused field. False when nothing
  /// that takes text has the focus.
  Future<bool> typeText(String text);

  Future<bool> pressKey(ServiceKey key);

  Future<bool> pressButton(ServiceButton button);
}
