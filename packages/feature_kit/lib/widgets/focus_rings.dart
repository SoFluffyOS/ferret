import 'package:flutter/widgets.dart';

/// Builds a button with [keyboardFocused]: true while keyboard focus is on
/// it. A ghost button draws its grey outline inside and the design
/// system's accent ring outside, so pass `borderWidth: 0` while this is
/// true and only the accent ring shows.
class ButtonFocusRing extends StatefulWidget {
  const ButtonFocusRing({super.key, required this.builder});

  final Widget Function(BuildContext context, bool keyboardFocused) builder;

  @override
  State<ButtonFocusRing> createState() => _ButtonFocusRingState();
}

class _ButtonFocusRingState extends State<ButtonFocusRing> {
  bool _hasFocus = false;

  // A tap can focus the button too; its outline stays then, because the
  // ring only shows for the keyboard.
  bool get _isKeyboard =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    if (_hasFocus && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
      child: widget.builder(context, _hasFocus && _isKeyboard),
    );
  }
}

/// Builds something focusable, such as a tappable card, with its focus
/// node, rebuilt whenever focus moves in or out of it. A `Tappable` shows
/// its focus state while focus is anywhere inside it, so a card around a
/// focused button would draw a second ring: draw the card's own ring only
/// while `node.hasPrimaryFocus`.
class PrimaryFocusBuilder extends StatefulWidget {
  const PrimaryFocusBuilder({super.key, required this.builder, this.focusNode});

  /// Left out, it makes and keeps one of its own.
  final FocusNode? focusNode;
  final Widget Function(BuildContext context, FocusNode node) builder;

  @override
  State<PrimaryFocusBuilder> createState() => _PrimaryFocusBuilderState();
}

class _PrimaryFocusBuilderState extends State<PrimaryFocusBuilder> {
  FocusNode? _own;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = _node;

    return ListenableBuilder(
      listenable: node,
      builder: (context, _) => widget.builder(context, node),
    );
  }
}

extension FocusInside on FocusNode {
  /// Focus is on something inside this, not on this itself.
  bool get focusIsInside => hasFocus && !hasPrimaryFocus;
}
