import 'package:pigeon/pigeon.dart';

// Regenerate with `dart run pigeon --input pigeon/messages.dart` from the
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

/// What this Mac lets Ferret do to take its own keyboard and mouse.
class NativeCaptureAccess {
  NativeCaptureAccess({
    required this.inputMonitoring,
    required this.accessibility,
  });

  /// Input Monitoring: seeing keys typed in other apps.
  bool inputMonitoring;

  /// Accessibility: holding events back from other apps.
  bool accessibility;
}

enum NativeCaptureKind {
  /// Relative move by `x`, `y` points.
  move,

  /// `code` is 0 left, 1 right, 2 middle.
  button,

  /// Scroll by `x`, `y` points, as macOS reports it: positive `y` moves
  /// the content down (toward the top of the page).
  scroll,

  /// `code` is the macOS virtual key code; `text` what it types.
  key,

  /// The modifier keys changed; `modifiers` holds the ones down now.
  modifiers,
}

/// One event taken from this Mac's own keyboard or mouse.
class NativeCapturedEvent {
  NativeCapturedEvent({
    required this.kind,
    required this.x,
    required this.y,
    required this.code,
    required this.pressed,
    required this.modifiers,
    required this.isRepeat,
    this.text,
  });

  NativeCaptureKind kind;
  double x;
  double y;
  int code;
  bool pressed;

  /// Bits: 1 shift, 2 control, 4 alt (Option), 8 meta (Command).
  int modifiers;

  /// A key held down long enough to repeat.
  bool isRepeat;
  String? text;
}

/// A switch combination pressed anywhere on the Mac.
enum NativeSwitchKey {
  /// ⌃⌥→: to the next computer.
  next,

  /// ⌃⌥⎋: back to this Mac.
  home,
}

/// Why taking the keyboard and mouse stopped on its own.
enum NativeCaptureEnd {
  /// ⌃⌥⎋ was pressed.
  homeKey,

  /// A password field turned on secure input, which hides keys from
  /// Ferret; they'd be typed on this Mac instead.
  secureInput,

  /// macOS turned the event tap off and it couldn't come back.
  tapFailed,
}

/// Takes this Mac's own keyboard and mouse away from it, to send them to
/// another computer. macOS only.
@HostApi()
abstract class InputCaptureHostApi {
  NativeCaptureAccess captureAccess();

  /// Shows the Input Monitoring and Accessibility prompts. macOS shows each
  /// only once. Returns whether both are on now.
  bool requestCaptureAccess();

  /// Opens System Settings where the missing one is turned on: Input
  /// Monitoring first, then Accessibility.
  void openCaptureSettings();

  /// Whether a password field holds secure input right now.
  bool secureInputOn();

  /// Listens for ⌃⌥→ and ⌃⌥⎋ anywhere on the Mac, or stops. False when
  /// the Mac refused a combination, such as when another app has it.
  bool setSwitchKeys(bool enabled);

  /// Starts holding back every key and mouse event and sending them here,
  /// with the pointer frozen and hidden. Returns the modifier bits held
  /// right now, or -1 when it couldn't start.
  int startCapture();

  /// Gives the keyboard and mouse back to this Mac.
  void stopCapture();
}

@FlutterApi()
abstract class InputCaptureFlutterApi {
  /// Events taken since the last call, in order; moves and scrolls added
  /// up in between.
  void onCaptured(List<NativeCapturedEvent> events);

  void onSwitchKey(NativeSwitchKey key);

  /// Capture stopped on its own; the keyboard and mouse are back already.
  void onCaptureEnded(NativeCaptureEnd reason);
}
