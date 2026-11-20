import 'package:ferret_remote_input/src/keys/keys.dart';

/// One thing to do with the pointer or the keyboard.
sealed class InputAction {
  const InputAction();
}

/// Moves the pointer by [dx], [dy] logical pixels.
final class MoveAction extends InputAction {
  const MoveAction(this.dx, this.dy);

  final int dx;
  final int dy;

  @override
  bool operator ==(Object other) =>
      other is MoveAction && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(MoveAction, dx, dy);

  @override
  String toString() => 'MoveAction($dx, $dy)';
}

final class ButtonAction extends InputAction {
  const ButtonAction(this.button, {required this.pressed});

  final PointerButton button;
  final bool pressed;

  @override
  bool operator ==(Object other) =>
      other is ButtonAction &&
      other.button == button &&
      other.pressed == pressed;

  @override
  int get hashCode => Object.hash(ButtonAction, button, pressed);

  @override
  String toString() => 'ButtonAction($button, pressed: $pressed)';
}

/// Scrolls by [dx], [dy] logical pixels; positive [dy] scrolls down.
final class ScrollAction extends InputAction {
  const ScrollAction(this.dx, this.dy);

  final int dx;
  final int dy;

  @override
  bool operator ==(Object other) =>
      other is ScrollAction && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(ScrollAction, dx, dy);

  @override
  String toString() => 'ScrollAction($dx, $dy)';
}

final class KeyAction extends InputAction {
  const KeyAction(this.key, {required this.pressed, this.modifiers = const {}});

  final InputKey key;
  final bool pressed;
  final Set<KeyModifier> modifiers;

  @override
  bool operator ==(Object other) =>
      other is KeyAction &&
      other.key == key &&
      other.pressed == pressed &&
      other.modifiers.length == modifiers.length &&
      other.modifiers.containsAll(modifiers);

  @override
  int get hashCode => Object.hash(
    KeyAction,
    key,
    pressed,
    KeyModifier.bitsOf(modifiers),
  );

  @override
  String toString() => 'KeyAction($key, pressed: $pressed, $modifiers)';
}

/// Types [text] as it is.
final class TextAction extends InputAction {
  const TextAction(this.text);

  final String text;

  @override
  bool operator ==(Object other) => other is TextAction && other.text == text;

  @override
  int get hashCode => Object.hash(TextAction, text);

  @override
  String toString() => 'TextAction(${text.length} characters)';
}

/// Holds exactly [held] modifier keys down on their own, such as Shift for a
/// Shift-click, until the next one. An empty set lets them all go.
final class ModifiersAction extends InputAction {
  const ModifiersAction(this.held);

  final Set<KeyModifier> held;

  @override
  bool operator ==(Object other) =>
      other is ModifiersAction &&
      other.held.length == held.length &&
      other.held.containsAll(held);

  @override
  int get hashCode => Object.hash(ModifiersAction, KeyModifier.bitsOf(held));

  @override
  String toString() => 'ModifiersAction($held)';
}
