/// One thing a tier can inject into the phone, as if its owner did it:
/// a touch, a scroll, a key or typed text.
sealed class PowerInput {
  const PowerInput();
}

enum TouchAction { down, move, up, cancel }

/// A finger going down, moving or lifting at ([x], [y]): fractions of the
/// screen as it is turned right now, from the top left corner.
final class PowerTouch extends PowerInput {
  const PowerTouch(this.action, this.x, this.y);

  final TouchAction action;
  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is PowerTouch &&
      other.action == action &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(PowerTouch, action, x, y);

  @override
  String toString() => 'PowerTouch(${action.name}, $x, $y)';
}

/// What is under ([x], [y]) scrolls by wheel notches: positive
/// [horizontal] is right, positive [vertical] is up.
final class PowerScroll extends PowerInput {
  const PowerScroll(this.x, this.y, {this.horizontal = 0, this.vertical = 0});

  final double x;
  final double y;
  final double horizontal;
  final double vertical;

  @override
  bool operator ==(Object other) =>
      other is PowerScroll &&
      other.x == x &&
      other.y == y &&
      other.horizontal == horizontal &&
      other.vertical == vertical;

  @override
  int get hashCode => Object.hash(PowerScroll, x, y, horizontal, vertical);

  @override
  String toString() => 'PowerScroll($x, $y, $horizontal, $vertical)';
}

/// An Android key ([keyCode] is a `KeyEvent.KEYCODE_*`) going down or up
/// with the `KeyEvent.META_*` bits in [metaState] held.
final class PowerKey extends PowerInput {
  const PowerKey(this.keyCode, {required this.down, this.metaState = 0});

  final int keyCode;
  final bool down;
  final int metaState;

  @override
  bool operator ==(Object other) =>
      other is PowerKey &&
      other.keyCode == keyCode &&
      other.down == down &&
      other.metaState == metaState;

  @override
  int get hashCode => Object.hash(PowerKey, keyCode, down, metaState);

  @override
  String toString() => 'PowerKey($keyCode, down: $down, meta: $metaState)';
}

/// Text typed on the phone's virtual keyboard. Characters it has no key
/// for are left out.
final class PowerText extends PowerInput {
  const PowerText(this.text);

  final String text;

  @override
  bool operator ==(Object other) => other is PowerText && other.text == text;

  @override
  int get hashCode => Object.hash(PowerText, text);

  @override
  String toString() => 'PowerText(${text.length} characters)';
}
