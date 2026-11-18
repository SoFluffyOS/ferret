import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/services.dart';

/// Turns this computer's key presses into what a route understands.
abstract final class MirrorKeys {
  static const _keyboardPage = 0x07;

  /// The USB HID usage of [key] on the keyboard page, or null for a key
  /// that isn't on it, such as a media key.
  static int? usageOf(PhysicalKeyboardKey key) {
    final page = key.usbHidUsage >> 16;
    final usage = key.usbHidUsage & 0xFFFF;
    if (page != _keyboardPage || usage == 0) {
      return null;
    }

    return usage;
  }

  /// [event] as a route's key press, or null for a key no route can map.
  /// A key held down repeats as more presses.
  static MirrorKey? keyOf(
    KeyEvent event, {
    Set<KeyModifier> modifiers = const {},
  }) {
    final usage = usageOf(event.physicalKey);
    if (usage == null) {
      return null;
    }

    return switch (event) {
      KeyUpEvent() => MirrorKey(
        phase: .up,
        usage: usage,
        modifiers: modifiers,
      ),
      KeyRepeatEvent() => MirrorKey(
        phase: .down,
        usage: usage,
        modifiers: modifiers,
        repeat: 1,
      ),
      _ => MirrorKey(phase: .down, usage: usage, modifiers: modifiers),
    };
  }

  /// The modifier keys held down on [keyboard] right now.
  static Set<KeyModifier> modifiersOf(HardwareKeyboard keyboard) => {
    if (keyboard.isShiftPressed) .shift,
    if (keyboard.isControlPressed) .control,
    if (keyboard.isAltPressed) .alt,
    if (keyboard.isMetaPressed) .meta,
  };
}
