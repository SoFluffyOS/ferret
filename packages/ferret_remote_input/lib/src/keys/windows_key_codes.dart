import 'package:ferret_remote_input/src/keys/input_key.dart';
import 'package:ferret_remote_input/src/keys/key_modifier.dart';

/// Windows virtual-key codes (`VK_*` in `WinUser.h`).
abstract final class WindowsKeyCodes {
  static final Map<InputKey, int> keys = {
    .enter: 0x0D,
    .backspace: 0x08,
    .delete: 0x2E,
    .tab: 0x09,
    .escape: 0x1B,
    .space: 0x20,
    .arrowLeft: 0x25,
    .arrowUp: 0x26,
    .arrowRight: 0x27,
    .arrowDown: 0x28,
    .home: 0x24,
    .end: 0x23,
    .pageUp: 0x21,
    .pageDown: 0x22,
    .mediaPlayPause: 0xB3,
    .mediaNext: 0xB0,
    .mediaPrevious: 0xB1,
    .volumeMute: 0xAD,
    .volumeDown: 0xAE,
    .volumeUp: 0xAF,
    for (var index = 0; index < 12; index++)
      InputKey.values.byName('f${index + 1}'): 0x70 + index,
    for (var index = 0; index < 26; index++)
      InputKey.values.byName(String.fromCharCode(0x61 + index)): 0x41 + index,
    for (var index = 0; index < 10; index++)
      InputKey.values.byName('digit$index'): 0x30 + index,
    .semicolon: 0xBA,
    .equal: 0xBB,
    .comma: 0xBC,
    .minus: 0xBD,
    .period: 0xBE,
    .slash: 0xBF,
    .backquote: 0xC0,
    .bracketLeft: 0xDB,
    .backslash: 0xDC,
    .bracketRight: 0xDD,
    .quote: 0xDE,
  };

  static const Map<KeyModifier, int> modifiers = {
    .shift: 0x10,
    .control: 0x11,
    .alt: 0x12,
    .meta: 0x5B,
  };
}
