import 'package:ferret_remote_input/src/keys/input_key.dart';
import 'package:ferret_remote_input/src/keys/key_modifier.dart';

/// Linux input event codes (`KEY_*` in `linux/input-event-codes.h`), for
/// uinput and ydotool.
abstract final class LinuxKeyCodes {
  static const Map<InputKey, int> keys = {
    .escape: 1,
    .digit1: 2,
    .digit2: 3,
    .digit3: 4,
    .digit4: 5,
    .digit5: 6,
    .digit6: 7,
    .digit7: 8,
    .digit8: 9,
    .digit9: 10,
    .digit0: 11,
    .backspace: 14,
    .tab: 15,
    .q: 16,
    .w: 17,
    .e: 18,
    .r: 19,
    .t: 20,
    .y: 21,
    .u: 22,
    .i: 23,
    .o: 24,
    .p: 25,
    .enter: 28,
    .a: 30,
    .s: 31,
    .d: 32,
    .f: 33,
    .g: 34,
    .h: 35,
    .j: 36,
    .k: 37,
    .l: 38,
    .z: 44,
    .x: 45,
    .c: 46,
    .v: 47,
    .b: 48,
    .n: 49,
    .m: 50,
    .space: 57,
    .f1: 59,
    .f2: 60,
    .f3: 61,
    .f4: 62,
    .f5: 63,
    .f6: 64,
    .f7: 65,
    .f8: 66,
    .f9: 67,
    .f10: 68,
    .f11: 87,
    .f12: 88,
    .home: 102,
    .arrowUp: 103,
    .pageUp: 104,
    .arrowLeft: 105,
    .arrowRight: 106,
    .end: 107,
    .arrowDown: 108,
    .pageDown: 109,
    .delete: 111,
    .volumeMute: 113,
    .volumeDown: 114,
    .volumeUp: 115,
    .mediaNext: 163,
    .mediaPlayPause: 164,
    .mediaPrevious: 165,
  };

  static const Map<KeyModifier, int> modifiers = {
    .control: 29,
    .shift: 42,
    .alt: 56,
    .meta: 125,
  };

  /// Punctuation on a US keyboard, to type text through uinput.
  static const minus = 12;
  static const equal = 13;
  static const leftBrace = 26;
  static const rightBrace = 27;
  static const semicolon = 39;
  static const apostrophe = 40;
  static const grave = 41;
  static const backslash = 43;
  static const comma = 51;
  static const dot = 52;
  static const slash = 53;

  static const buttonLeft = 0x110;
  static const buttonRight = 0x111;
  static const buttonMiddle = 0x112;
}
