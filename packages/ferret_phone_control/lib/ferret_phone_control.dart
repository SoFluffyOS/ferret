/// Lets a paired computer tap, swipe and type on an Android phone while it
/// shows its screen: through the power-ups helper when Shizuku or root is
/// on, or else an accessibility service its owner turned on. Nothing acts
/// until the app arms it.
library;

export 'package:ferret_phone_control/src/android_keys.dart';
export 'package:ferret_phone_control/src/control_path.dart';
export 'package:ferret_phone_control/src/control_service.dart';
export 'package:ferret_phone_control/src/phone_button.dart';
export 'package:ferret_phone_control/src/phone_control.dart';
export 'package:ferret_phone_control/src/pigeon_control_service.dart';
export 'package:ferret_phone_control/src/unsupported_control_service.dart';
export 'package:ferret_power/ferret_power.dart'
    show PowerCapabilities, TouchAction;
