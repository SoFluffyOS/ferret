/// USB HID keyboard usages (page 7) to Android keycodes
/// (`android.view.KeyEvent.KEYCODE_*`), by key position.
abstract final class HidKeycodes {
  static const int _usageA = 0x04;
  static const int _usageZ = 0x1D;
  static const int _usage1 = 0x1E;
  static const int _usage9 = 0x26;
  static const int _usageF1 = 0x3A;
  static const int _usageF12 = 0x45;
  static const int _usageKeypad1 = 0x59;
  static const int _usageKeypad9 = 0x61;

  static const int _keycodeA = 29;
  static const int _keycode1 = 8;
  static const int _keycodeF1 = 131;
  static const int _keycodeKeypad1 = 145;

  static const Map<int, int> _others = {
    0x27: 7, // 0
    0x28: 66, // Enter
    0x29: 111, // Escape
    0x2A: 67, // Backspace (KEYCODE_DEL)
    0x2B: 61, // Tab
    0x2C: 62, // Space
    0x2D: 69, // -
    0x2E: 70, // =
    0x2F: 71, // [
    0x30: 72, // ]
    0x31: 73, // \
    0x33: 74, // ;
    0x34: 75, // '
    0x35: 68, // `
    0x36: 55, // ,
    0x37: 56, // .
    0x38: 76, // /
    0x39: 115, // Caps Lock
    0x46: 120, // Print Screen (KEYCODE_SYSRQ)
    0x47: 116, // Scroll Lock
    0x48: 121, // Pause (KEYCODE_BREAK)
    0x49: 124, // Insert
    0x4A: 122, // Home (KEYCODE_MOVE_HOME)
    0x4B: 92, // Page Up
    0x4C: 112, // Delete (KEYCODE_FORWARD_DEL)
    0x4D: 123, // End (KEYCODE_MOVE_END)
    0x4E: 93, // Page Down
    0x4F: 22, // Right
    0x50: 21, // Left
    0x51: 20, // Down
    0x52: 19, // Up
    0x53: 143, // Num Lock
    0x54: 154, // Keypad /
    0x55: 155, // Keypad *
    0x56: 156, // Keypad -
    0x57: 157, // Keypad +
    0x58: 160, // Keypad Enter
    0x62: 144, // Keypad 0
    0x63: 158, // Keypad .
    0x65: 82, // Menu
    0x67: 161, // Keypad =
    0xE0: 113, // Left Control
    0xE1: 59, // Left Shift
    0xE2: 57, // Left Alt
    0xE3: 117, // Left Meta
    0xE4: 114, // Right Control
    0xE5: 60, // Right Shift
    0xE6: 58, // Right Alt
    0xE7: 118, // Right Meta
  };

  /// The Android keycode for [usage], or null when Android has no such key.
  static int? keycodeFor(int usage) {
    if (usage >= _usageA && usage <= _usageZ) {
      return _keycodeA + usage - _usageA;
    }

    if (usage >= _usage1 && usage <= _usage9) {
      return _keycode1 + usage - _usage1;
    }

    if (usage >= _usageF1 && usage <= _usageF12) {
      return _keycodeF1 + usage - _usageF1;
    }

    if (usage >= _usageKeypad1 && usage <= _usageKeypad9) {
      return _keycodeKeypad1 + usage - _usageKeypad1;
    }

    return _others[usage];
  }
}
