import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/ui/widgets/keyboard_lines.dart';

/// One line of [KeyboardLines]: the focus node [builder] hands to the
/// line's tappable, and the [keys] the line answers while it has the
/// keyboard, such as ⌘V on a device to send it the clipboard.
class KeyboardLine extends StatefulWidget {
  const KeyboardLine({super.key, required this.builder, this.keys = const {}});

  final Widget Function(BuildContext context, FocusNode focusNode) builder;

  /// Answered before the line's own Enter and Space, so a line can give
  /// them its own meaning.
  final Map<SingleActivator, VoidCallback> keys;

  @override
  State<KeyboardLine> createState() => _KeyboardLineState();
}

class _KeyboardLineState extends State<KeyboardLine> {
  late final FocusNode _node = FocusNode(
    debugLabel: 'KeyboardLine',
    onKeyEvent: _onKey,
  );
  KeyboardLinesState? _lines;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lines = KeyboardLines.maybeOf(context);
    if (identical(lines, _lines)) {
      return;
    }

    _lines?.remove(_node);
    _lines = lines?..add(_node);
  }

  @override
  void dispose() {
    _lines?.remove(_node);
    _node.dispose();
    super.dispose();
  }

  /// Only keys pressed on the line itself: a button inside it keeps its own.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!node.hasPrimaryFocus) {
      return .ignored;
    }

    for (final MapEntry(key: activator, value: onKey) in widget.keys.entries) {
      if (activator.accepts(event, HardwareKeyboard.instance)) {
        onKey();
        return .handled;
      }
    }

    return .ignored;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _node);
}
