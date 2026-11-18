import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:remote_input/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A text field whose every change goes to the other device as typing:
/// new characters as text, deletions as Backspace. Words still being
/// composed by the keyboard (such as with predictive text or an IME) wait
/// until they are done. Enter sends Enter and clears the field.
class KeyboardField extends StatefulWidget {
  const KeyboardField({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.onEnter,
  });

  final String hint;
  final ValueChanged<TextChange> onChanged;
  final VoidCallback onEnter;

  @override
  State<KeyboardField> createState() => _KeyboardFieldState();
}

class _KeyboardFieldState extends State<KeyboardField> {
  final TextEditingController _controller = TextEditingController();
  String _sent = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onValue);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onValue)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InputText(
    controller: _controller,
    hintText: widget.hint,
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.send,
    onSubmitted: (_) => _onEnter(),
    onEditingComplete: _keepKeyboardOpen,
  );

  void _keepKeyboardOpen() {}

  void _onValue() {
    final value = _controller.value;
    if (value.composing.isValid && !value.composing.isCollapsed) {
      return;
    }

    final text = value.text;
    if (text == _sent) {
      return;
    }

    final change = TextDiff.between(_sent, text);
    _sent = text;
    widget.onChanged(change);
  }

  void _onEnter() {
    _sent = '';
    _controller.clear();
    widget.onEnter();
  }
}
