import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/services.dart';
import 'package:mirroring/models/models.dart';

/// Turns this computer's key presses into what a route understands.
abstract final class MirrorKeys {
  static const _keyboardPage = 0x07;
  static const _firstPrintable = 0x20;
  static const _delete = 0x7F;

  /// Shortcuts that stay with this computer's window: close, quit,
  /// minimise, and the picture's sizes.
  static final Set<LogicalKeyboardKey> _kept = {
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyQ,
    LogicalKeyboardKey.keyM,
    LogicalKeyboardKey.digit0,
    LogicalKeyboardKey.equal,
    LogicalKeyboardKey.minus,
  };

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

  /// What [event] means for a device that takes [abilities], or null to
  /// leave the key to this computer. [shortcut] is this computer's own
  /// shortcut key: Command on a Mac, Control elsewhere.
  ///
  /// Letters and symbols go as text, so they come out the same in any
  /// keyboard layout; what the device's key map lacks goes through its
  /// clipboard. Everything else goes as keys.
  static InputAction? actionOf(
    KeyEvent event, {
    required Set<KeyModifier> modifiers,
    required Set<ControlAbility> abilities,
    KeyModifier shortcut = .meta,
  }) {
    final isUp = event is KeyUpEvent;
    if (modifiers.contains(shortcut)) {
      return _shortcutOf(event, modifiers, abilities, shortcut);
    }

    final isBack =
        event.logicalKey == LogicalKeyboardKey.escape &&
        abilities.contains(ControlAbility.buttons);
    if (isBack && isUp) {
      return const NoInput();
    }

    if (isBack) {
      return const PressButton(.back);
    }

    final typed = _typedOf(event, modifiers, abilities);
    if (typed != null) {
      return typed;
    }

    if (!abilities.contains(ControlAbility.keys)) {
      return null;
    }

    return _sendKey(event, modifiers);
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

  /// A press with this computer's shortcut key held: Ferret's own
  /// shortcuts first, then the window's, and the rest reaches the device
  /// as its Control shortcut, so copy, cut, undo and select all work the
  /// way the hands already know.
  static InputAction? _shortcutOf(
    KeyEvent event,
    Set<KeyModifier> modifiers,
    Set<ControlAbility> abilities,
    KeyModifier shortcut,
  ) {
    final key = event.logicalKey;
    final plain = modifiers.length == 1;
    if (_kept.contains(key) || !plain) {
      return null;
    }

    final own = _ownShortcut(key, abilities);
    if (own != null && event is KeyDownEvent) {
      return own;
    }

    if (own != null) {
      return const NoInput();
    }

    if (!abilities.contains(ControlAbility.keys)) {
      return null;
    }

    return _sendKey(event, const {.control});
  }

  static InputAction? _ownShortcut(
    LogicalKeyboardKey key,
    Set<ControlAbility> abilities,
  ) {
    final canPress = abilities.contains(ControlAbility.buttons);
    if (key == LogicalKeyboardKey.keyV &&
        abilities.contains(ControlAbility.clipboard)) {
      return const PasteClipboard();
    }

    if (key == LogicalKeyboardKey.keyK &&
        abilities.contains(ControlAbility.text)) {
      return const OpenTextField();
    }

    if (!canPress) {
      return null;
    }

    if (key == LogicalKeyboardKey.digit1) {
      return const PressButton(.home);
    }

    if (key == LogicalKeyboardKey.digit2) {
      return const PressButton(.recents);
    }

    if (key == LogicalKeyboardKey.bracketLeft) {
      return const PressButton(.back);
    }

    if (key == LogicalKeyboardKey.keyR) {
      return const PressButton(.rotate);
    }

    return null;
  }

  /// The character [event] types, as text for the device.
  static InputAction? _typedOf(
    KeyEvent event,
    Set<KeyModifier> modifiers,
    Set<ControlAbility> abilities,
  ) {
    final character = event.character;
    final asShortcut =
        modifiers.contains(KeyModifier.control) ||
        modifiers.contains(KeyModifier.meta);
    if (character == null ||
        asShortcut ||
        !abilities.contains(ControlAbility.text) ||
        !_isPrintable(character)) {
      return null;
    }

    return textAction(character, abilities);
  }

  /// [text] as the device can take it: typed when its key map has every
  /// character, through its clipboard otherwise.
  static InputAction textAction(String text, Set<ControlAbility> abilities) {
    final plain = text.runes.every(
      (rune) => rune >= _firstPrintable && rune < _delete,
    );
    if (plain || !abilities.contains(ControlAbility.clipboard)) {
      return SendText(text);
    }

    return PasteText(text);
  }

  static bool _isPrintable(String character) => character.runes.every(
    (rune) => rune >= _firstPrintable && rune != _delete,
  );

  static InputAction? _sendKey(KeyEvent event, Set<KeyModifier> modifiers) {
    final key = keyOf(event, modifiers: modifiers);
    if (key == null) {
      return null;
    }

    return SendKey(key);
  }
}
