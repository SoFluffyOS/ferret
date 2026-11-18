/// Moves the pointer, clicks, scrolls and types on this computer for
/// another device: CGEvent on macOS, SendInput on Windows, and uinput,
/// xdotool or ydotool on Linux. Key names are the same on every platform.
library;

export 'package:ferret_remote_input/src/held_input.dart';
export 'package:ferret_remote_input/src/injector_status.dart';
export 'package:ferret_remote_input/src/input_action.dart';
export 'package:ferret_remote_input/src/input_injector.dart';
export 'package:ferret_remote_input/src/key_chords.dart';
export 'package:ferret_remote_input/src/keys/keys.dart';
export 'package:ferret_remote_input/src/linux/linux.dart';
export 'package:ferret_remote_input/src/messages.g.dart'
    show NativeEventKind, NativeInputEvent, NativeAccess, RemoteInputHostApi;
export 'package:ferret_remote_input/src/native_injector.dart';
export 'package:ferret_remote_input/src/unsupported_injector.dart';
