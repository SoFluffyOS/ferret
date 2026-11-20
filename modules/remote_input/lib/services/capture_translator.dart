import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/services/input_codec.dart';

/// Where translated input goes: the control of another computer.
abstract interface class InputSink {
  void move(double dx, double dy);

  void scroll(double dx, double dy);

  void add(InputEvent event);
}

/// Turns what this Mac's own keyboard and mouse did into input for another
/// computer: moves, buttons and scrolls as they are, typed characters as
/// text (so the other keyboard layout doesn't matter), shortcuts and keys
/// that type nothing as keys, and modifier keys on their own.
///
/// With [swapCommandAndControl], for a PC or Linux computer, ⌘ is Ctrl
/// there and ⌃ the Windows or Super key, so ⌘C copies on both.
class CaptureTranslator {
  CaptureTranslator({this.swapCommandAndControl = false});

  final bool swapCommandAndControl;

  /// The switch keys' own modifiers, never sent on entering.
  static const switchModifiers = {KeyModifier.control, KeyModifier.alt};

  /// macOS virtual key codes to keys; the keypad's Enter is Enter too.
  static final Map<int, InputKey> macKeys = {
    for (final MapEntry(:key, :value) in MacKeyCodes.keys.entries)
      if (!value.isMedia) value.code: key,
    0x4C: InputKey.enter,
  };

  Set<KeyModifier> _sent = const {};
  final Map<int, (InputKey, Set<KeyModifier>)> _keysDown = {};

  /// The modifiers to send on entering, for [held] down on this Mac right
  /// now, less ⌃⌥ that were pressed for the switch.
  Set<KeyModifier> enter(Set<KeyModifier> held) {
    _keysDown.clear();
    _sent = _mapped(held.difference(switchModifiers));
    return _sent;
  }

  void translate(NativeCapturedEvent event, InputSink sink) {
    switch (event.kind) {
      case .move:
        sink.move(event.x, event.y);
      case .scroll:
        sink.scroll(-event.x, -event.y);
      case .button:
        final button = switch (event.code) {
          0 => PointerButton.left,
          1 => PointerButton.right,
          2 => PointerButton.middle,
          _ => null,
        };
        if (button == null) {
          return;
        }

        sink.add(InputCodec.button(button, pressed: event.pressed));
      case .modifiers:
        final held = _mapped(_modifiersOf(event.modifiers));
        if (held.length == _sent.length && held.containsAll(_sent)) {
          return;
        }

        _sent = held;
        sink.add(InputCodec.modifierState(held));
      case .key:
        _key(event, sink);
    }
  }

  void _key(NativeCapturedEvent event, InputSink sink) {
    final code = event.code;
    if (!event.pressed) {
      final (key, modifiers) = _keysDown.remove(code) ?? (null, null);
      if (key == null) {
        return;
      }

      sink.add(InputCodec.key(key, pressed: false, modifiers: modifiers ?? {}));
      return;
    }

    final held = _mapped(_modifiersOf(event.modifiers));
    final isShortcut = held.any((modifier) => modifier != .shift);
    final key = macKeys[code];
    if (key != null && (isShortcut || !_typesText(key))) {
      _keysDown[code] = (key, held);
      sink.add(InputCodec.key(key, pressed: true, modifiers: held));
      return;
    }

    final text = event.text ?? '';
    if (text.isEmpty || isShortcut || !_isPrintable(text)) {
      return;
    }

    sink.add(InputCodec.text(text));
  }

  bool _typesText(InputKey key) => InputKey.ofCharacter(_nameOf(key)) == key;

  String _nameOf(InputKey key) => switch (key) {
    .space => ' ',
    final digit when digit.name.startsWith('digit') => digit.name.substring(5),
    final other => other.name,
  };

  /// Not a control character, nor one of macOS's private codes for keys
  /// such as F13.
  bool _isPrintable(String text) => text.runes.every(
    (rune) => rune >= 0x20 && rune != 0x7f && (rune < 0xf700 || rune > 0xf8ff),
  );

  Set<KeyModifier> _modifiersOf(int bits) => {
    for (final modifier in KeyModifier.values)
      if (bits & modifier.bit != 0) modifier,
  };

  Set<KeyModifier> _mapped(Set<KeyModifier> held) {
    if (!swapCommandAndControl) {
      return held;
    }

    return {
      for (final modifier in held)
        switch (modifier) {
          .meta => KeyModifier.control,
          .control => KeyModifier.meta,
          _ => modifier,
        },
    };
  }
}
