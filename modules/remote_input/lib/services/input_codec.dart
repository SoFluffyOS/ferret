import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:protocol/remote_input.dart';

/// Turns the wire's input events into actions for the injector, and the
/// controller's taps and keys into events, with sane bounds so a broken
/// controller can't fling the pointer or type a novel.
abstract final class InputCodec {
  /// Version of the `ferret.remote_input.v1` messages this side speaks.
  static const protocolVersion = 1;

  static const maxEventsPerBatch = 512;
  static const maxDelta = 10000;
  static const maxTextLength = 4096;

  /// Wire keys to platform-neutral keys, matched by name: `KEY_ARROW_LEFT`
  /// is [InputKey.arrowLeft].
  static final Map<Key, InputKey> keys = {
    for (final key in InputKey.values) ?_wireKey(key): key,
  };

  static final Map<InputKey, Key> _wireKeys = {
    for (final MapEntry(:key, :value) in keys.entries) value: key,
  };

  static const Map<Modifier, KeyModifier> modifiers = {
    Modifier.MODIFIER_SHIFT: .shift,
    Modifier.MODIFIER_CONTROL: .control,
    Modifier.MODIFIER_ALT: .alt,
    Modifier.MODIFIER_META: .meta,
  };

  static final Map<KeyModifier, Modifier> _wireModifiers = {
    for (final MapEntry(:key, :value) in modifiers.entries) value: key,
  };

  static const Map<MouseButton, PointerButton> buttons = {
    MouseButton.MOUSE_BUTTON_LEFT: .left,
    MouseButton.MOUSE_BUTTON_RIGHT: .right,
    MouseButton.MOUSE_BUTTON_MIDDLE: .middle,
  };

  /// The actions in [batch], skipping what this side doesn't know.
  static List<InputAction> actionsOf(InputBatch batch) => [
    for (final event in batch.events.take(maxEventsPerBatch)) ?actionOf(event),
  ];

  static InputAction? actionOf(InputEvent event) {
    switch (event.whichKind()) {
      case .move:
        return MoveAction(_bound(event.move.dx), _bound(event.move.dy));
      case .scroll:
        return ScrollAction(_bound(event.scroll.dx), _bound(event.scroll.dy));
      case .button:
        final button = buttons[event.button.button];
        if (button == null) {
          return null;
        }

        return ButtonAction(button, pressed: event.button.pressed);
      case .key:
        final key = keys[event.key.key];
        if (key == null) {
          return null;
        }

        return KeyAction(
          key,
          pressed: event.key.pressed,
          modifiers: {
            for (final modifier in event.key.modifiers) ?modifiers[modifier],
          },
        );
      case .text:
        final text = event.text.text;
        if (text.isEmpty) {
          return null;
        }

        if (text.length > maxTextLength) {
          return TextAction(text.substring(0, maxTextLength));
        }

        return TextAction(text);
      case .notSet:
        return null;
    }
  }

  static InputEvent move(int dx, int dy) => InputEvent(
    move: PointerMove(dx: dx, dy: dy),
  );

  static InputEvent scroll(int dx, int dy) => InputEvent(
    scroll: Scroll(dx: dx, dy: dy),
  );

  static InputEvent button(PointerButton button, {required bool pressed}) {
    final wire = switch (button) {
      .left => MouseButton.MOUSE_BUTTON_LEFT,
      .right => MouseButton.MOUSE_BUTTON_RIGHT,
      .middle => MouseButton.MOUSE_BUTTON_MIDDLE,
    };
    return InputEvent(
      button: ButtonEvent(button: wire, pressed: pressed),
    );
  }

  static InputEvent key(
    InputKey key, {
    required bool pressed,
    Set<KeyModifier> modifiers = const {},
  }) => InputEvent(
    key: KeyEvent(
      key: _wireKeys[key],
      pressed: pressed,
      modifiers: [
        for (final modifier in KeyModifier.values)
          if (modifiers.contains(modifier)) ?_wireModifiers[modifier],
      ],
    ),
  );

  static InputEvent text(String text) =>
      InputEvent(text: TextInput(text: text));

  static Key? _wireKey(InputKey key) {
    final name = switch (key.name) {
      final digit when digit.startsWith('digit') =>
        'KEY_DIGIT_${digit.substring(5)}',
      final camel =>
        'KEY_${camel.replaceAllMapped(RegExp('[A-Z]'), (match) => '_${match[0]}').toUpperCase()}',
    };
    for (final wire in Key.values) {
      if (wire.name == name) {
        return wire;
      }
    }

    return null;
  }

  static int _bound(int value) => value.clamp(-maxDelta, maxDelta);
}
