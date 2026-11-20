import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A list read line by line from the keyboard: ↑ and ↓ move between the
/// [KeyboardLine]s below it, top to bottom as they are drawn, skipping the
/// buttons inside each line, and Home and End jump to the first and the
/// last. Tab still reaches those buttons.
class KeyboardLines extends StatefulWidget {
  const KeyboardLines({super.key, required this.child});

  final Widget child;

  static final Set<KeyboardLinesState> _shown = {};

  /// The lines around [context], or null where there are none, such as on
  /// a page that doesn't take arrow keys.
  static KeyboardLinesState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<KeyboardLinesState>();

  /// The lines on the page [navigator] shows on top, if that page has any.
  static KeyboardLinesState? onTopOf(NavigatorState navigator) {
    for (final lines in _shown) {
      final context = lines.context;
      if (context.findAncestorStateOfType<NavigatorState>() == navigator &&
          (ModalRoute.isCurrentOf(context) ?? true)) {
        return lines;
      }
    }

    return null;
  }

  @override
  State<KeyboardLines> createState() => KeyboardLinesState();
}

class KeyboardLinesState extends State<KeyboardLines> {
  final Set<FocusNode> _lines = {};

  void add(FocusNode line) => _lines.add(line);

  void remove(FocusNode line) => _lines.remove(line);

  /// Steps for [move] that jump to the first and the last line.
  static const first = -1 << 30;
  static const last = 1 << 30;

  @override
  void initState() {
    super.initState();
    KeyboardLines._shown.add(this);
  }

  @override
  void dispose() {
    KeyboardLines._shown.remove(this);
    super.dispose();
  }

  /// Moves to the line [step] lines away from the one that has the focus,
  /// or to the first (down) or last (up) line when none has it; a step of
  /// [first] or [last] jumps there. Stops at either end, and says whether
  /// it moved.
  bool move(int step) {
    final ordered = [
      for (final line in _lines)
        if (line.context != null && line.canRequestFocus) line,
    ]..sort((a, b) => a.rect.top.compareTo(b.rect.top));
    if (ordered.isEmpty) {
      return false;
    }

    final current = ordered.indexWhere((line) => line.hasFocus);
    final next = switch ((current, step)) {
      (_, first) => 0,
      (_, last) => ordered.length - 1,
      (-1, > 0) => 0,
      (-1, _) => ordered.length - 1,
      _ => (current + step).clamp(0, ordered.length - 1),
    };
    final line = ordered[next];
    if (next == current && line.hasPrimaryFocus) {
      return false;
    }

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

    return true;
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

    final isTyping =
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null;
    final step = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.arrowUp => -1,
      _ when isTyping => 0,
      LogicalKeyboardKey.home => first,
      LogicalKeyboardKey.end => last,
      _ => 0,
    };
    if (step == 0 || HardwareKeyboard.instance.isMetaPressed) {
      return .ignored;
    }

    if (move(step)) {
      return .handled;
    }

    // Past the last line, ↓ may go on to what sits under the page, such
    // as the popover's shelf.
    final goesOn = KeyboardLinesExit.maybeOf(context)?.onPastEnd;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && goesOn != null) {
      goesOn();
    }

    return .handled;
  }
}

/// Where ↓ goes from the last of the [KeyboardLines] below it, such as
/// into the popover's shelf, the way Tab goes on from the page.
class KeyboardLinesExit extends InheritedWidget {
  const KeyboardLinesExit({
    super.key,
    required this.onPastEnd,
    required super.child,
  });

  final VoidCallback onPastEnd;

  static KeyboardLinesExit? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<KeyboardLinesExit>();

  @override
  bool updateShouldNotify(KeyboardLinesExit oldWidget) => false;
}
