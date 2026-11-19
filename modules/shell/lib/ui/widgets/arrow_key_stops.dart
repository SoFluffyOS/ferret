import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A column of lines walked with ↑ and ↓ as well as Tab, the way a list in
/// a sidebar is on every desktop: the arrows move from line to line and
/// stop at either end, Home and End jump to the first and the last. A
/// button inside a line is skipped; Tab still reaches it.
///
/// Unlike [KeyboardLines] it needs nothing from the lines: whatever takes
/// Tab below it is a stop.
class ArrowKeyStops extends StatelessWidget {
  const ArrowKeyStops({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: child,
    );
  }

  static KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    final hasModifier =
        keyboard.isMetaPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed;
    if (event is KeyUpEvent || hasModifier) {
      return .ignored;
    }

    final lines = _linesOf(node);
    final current = lines.indexWhere((line) => line.any(_hasKeyboard));
    if (current == -1) {
      return .ignored;
    }

    final target = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => current + 1,
      LogicalKeyboardKey.arrowUp => current - 1,
      LogicalKeyboardKey.home => 0,
      LogicalKeyboardKey.end => lines.length - 1,
      _ => null,
    };
    if (target == null) {
      return .ignored;
    }

    final line = _lineItself(lines[target.clamp(0, lines.length - 1)]);
    line.requestFocus();
    if (line.context case final lineContext?) {
      unawaited(
        Scrollable.ensureVisible(
          lineContext,
          alignmentPolicy: switch (target > current) {
            true => .keepVisibleAtEnd,
            false => .keepVisibleAtStart,
          },
        ),
      );
    }

    return .handled;
  }

  static bool _hasKeyboard(FocusNode stop) => stop.hasPrimaryFocus;

  /// The stops under [node], top to bottom, those that share a line
  /// together.
  static List<List<FocusNode>> _linesOf(FocusNode node) {
    final stops = [
      for (final stop in node.traversalDescendants)
        if (stop.context != null) stop,
    ]..sort((a, b) => a.rect.top.compareTo(b.rect.top));
    final lines = <List<FocusNode>>[];
    var bottom = double.negativeInfinity;
    for (final stop in stops) {
      if (stop.rect.center.dy < bottom) {
        lines.last.add(stop);
        continue;
      }

      lines.add([stop]);
      bottom = stop.rect.bottom;
    }

    return lines;
  }

  /// A line is wider than any button in it.
  static FocusNode _lineItself(List<FocusNode> line) => line.reduce(
    (widest, stop) => switch (stop.rect.width > widest.rect.width) {
      true => stop,
      false => widest,
    },
  );
}
