import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A list read line by line from the keyboard: ↑ and ↓ move between the
/// [KeyboardLine]s below it, top to bottom as they are drawn, skipping the
/// buttons inside each line. Tab still reaches those.
class KeyboardLines extends StatefulWidget {
  const KeyboardLines({super.key, required this.child});

  final Widget child;

  /// The lines around [context], or null where there are none, such as on
  /// a page that doesn't take arrow keys.
  static KeyboardLinesState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<KeyboardLinesState>();

  @override
  State<KeyboardLines> createState() => KeyboardLinesState();
}

class KeyboardLinesState extends State<KeyboardLines> {
  final Set<FocusNode> _lines = {};

  void add(FocusNode line) => _lines.add(line);

  void remove(FocusNode line) => _lines.remove(line);

  /// Moves to the line [step] lines away from the one that has the focus,
  /// or to the first (down) or last (up) line when none has it. Stops at
  /// either end.
  void move(int step) {
    final ordered = [
      for (final line in _lines)
        if (line.context != null && line.canRequestFocus) line,
    ]..sort((a, b) => a.rect.top.compareTo(b.rect.top));
    if (ordered.isEmpty) {
      return;
    }

    final current = ordered.indexWhere((line) => line.hasFocus);
    final next = switch ((current, step)) {
      (-1, > 0) => 0,
      (-1, _) => ordered.length - 1,
      _ => (current + step).clamp(0, ordered.length - 1),
    };
    final line = ordered[next];

    line.requestFocus();
    if (line.context case final lineContext?) {
      unawaited(
        Scrollable.ensureVisible(
          lineContext,
          alignmentPolicy: switch (step) {
            > 0 => .keepVisibleAtEnd,
            _ => .keepVisibleAtStart,
          },
        ),
      );
    }
  }

  /// Holds the keyboard when no line has it yet, so the first ↓ lands.
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      return .ignored;
    }

    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowUp => -1,
      _ => 0,
    };
    if (step == 0 || HardwareKeyboard.instance.isMetaPressed) {
      return .ignored;
    }

    move(step);
    return .handled;
  }
}
