/// Drives the device being shown: pointer, keys, text and its own
/// buttons. Positions are fractions of the picture (0 to 1 on each side),
/// so a route maps them to its own coordinates, whatever the size shown.
abstract interface class MirrorControl {
  Set<ControlAbility> get abilities;

  void pointer(MirrorPointer event);

  void key(MirrorKey event);

  /// Types [text] as if from a keyboard.
  void text(String text);

  void press(DeviceButton button);

  /// Puts [text] on the device's clipboard, pasting it when [paste] is set.
  void setClipboard(String text, {bool paste = false});
}

enum ControlAbility { pointer, keys, text, buttons, clipboard }

enum PointerPhase { down, move, up, cancel, hover, scroll }

class MirrorPointer {
  const MirrorPointer({
    required this.phase,
    required this.x,
    required this.y,
    this.pointerId = 0,
    this.buttons = 1,
    this.scrollX = 0,
    this.scrollY = 0,
  });

  final PointerPhase phase;

  /// Fractions of the picture's width and height.
  final double x;
  final double y;
  final int pointerId;

  /// Bit set of pressed buttons; bit 0 is the primary one.
  final int buttons;

  /// Scroll phase only, in notches: positive is right and down.
  final double scrollX;
  final double scrollY;
}

enum KeyPhase { down, up }

class MirrorKey {
  const MirrorKey({
    required this.phase,
    required this.usage,
    this.modifiers = const {},
    this.repeat = 0,
  });

  final KeyPhase phase;

  /// The USB HID usage (page 7), the one id every route can map from.
  final int usage;
  final Set<KeyModifier> modifiers;
  final int repeat;
}

enum KeyModifier { shift, control, alt, meta }

enum DeviceButton {
  back,
  home,
  recents,
  power,
  volumeUp,
  volumeDown,
  notifications,
  rotate,
}
