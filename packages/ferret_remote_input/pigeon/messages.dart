import 'package:pigeon/pigeon.dart';

// Regenerate with `fvm dart run pigeon --input pigeon/messages.dart` from the
// package folder. Linux is Dart only (lib/src/linux/), and phones never
// inject input, so only macOS and Windows have native code.
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'ferret_remote_input',
    dartOut: 'lib/src/messages.g.dart',
    cppHeaderOut: 'windows/messages.g.h',
    cppSourceOut: 'windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'ferret_remote_input'),
    swiftOut: 'macos/ferret_remote_input/Sources/ferret_remote_input/Messages.g.swift',
  ),
)
/// Whether this process may inject input.
class NativeAccess {
  NativeAccess({required this.granted, required this.needsPermission});

  bool granted;

  /// Granting needs the person, such as Accessibility on macOS.
  bool needsPermission;
}

enum NativeEventKind {
  /// Relative move by `x`, `y`.
  move,

  /// `code` is 0 left, 1 right, 2 middle.
  button,

  /// Relative scroll by `x`, `y` in pixels; positive `y` scrolls down.
  scroll,

  /// `code` is the platform's virtual key code.
  key,

  /// macOS only: `code` is an `NX_KEYTYPE_*` media key.
  mediaKey,

  /// Types `text`.
  text,
}

/// One input action, already in the platform's codes.
class NativeInputEvent {
  NativeInputEvent({
    required this.kind,
    required this.x,
    required this.y,
    required this.code,
    required this.pressed,
    required this.modifiers,
    this.text,
  });

  NativeEventKind kind;
  int x;
  int y;
  int code;
  bool pressed;

  /// Bits: 1 shift, 2 control, 4 alt, 8 meta. macOS sets them as event
  /// flags; Windows presses the modifier keys itself from Dart.
  int modifiers;
  String? text;
}

@HostApi()
abstract class RemoteInputHostApi {
  NativeAccess access();

  /// Asks for access, such as the macOS Accessibility prompt. Returns
  /// whether it is granted now.
  bool requestAccess();

  /// Opens the system page where people allow access.
  void openAccessSettings();

  /// Injects [events] in order.
  void inject(List<NativeInputEvent> events);

  /// Releases every button and key this process still holds down.
  void releaseAll();
}
