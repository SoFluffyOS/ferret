import 'package:flutter/widgets.dart';

/// Tells [builder] whether the pointer is over what it builds or the
/// keyboard's focus is inside it.
class RevealOnPointerOrFocus extends StatefulWidget {
  const RevealOnPointerOrFocus({super.key, required this.builder});

  final Widget Function(BuildContext context, bool isRevealed) builder;

  @override
  State<RevealOnPointerOrFocus> createState() => _RevealOnPointerOrFocusState();
}

class _RevealOnPointerOrFocusState extends State<RevealOnPointerOrFocus> {
  bool _isHovered = false;
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
        child: widget.builder(context, _isHovered || _hasFocus),
      ),
    );
  }
}
