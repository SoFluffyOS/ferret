import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A mouse button under the touchpad: down while the finger is on it, so
/// another finger can drag on the pad.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.label,
    required this.onPress,
    required this.onRelease,
  });

  final String label;
  final VoidCallback onPress;
  final VoidCallback onRelease;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> {
  int? _pointer;

  @override
  void dispose() {
    if (_pointer != null) {
      widget.onRelease();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final color = switch (_pointer) {
      null => palette.surface,
      _ => palette.accent.withValues(alpha: 0.25),
    };

    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        behavior: .opaque,
        onPointerDown: _onDown,
        onPointerUp: (event) => _onUp(event.pointer),
        onPointerCancel: (event) => _onUp(event.pointer),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: color,
            shape: Corners.shape(Corners.card),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.d16),
            child: Text(
              widget.label,
              textAlign: .center,
              style: typography.body2.copyWith(color: palette.text),
            ),
          ),
        ),
      ),
    );
  }

  void _onDown(PointerDownEvent event) {
    if (_pointer != null) {
      return;
    }

    setState(() => _pointer = event.pointer);
    widget.onPress();
  }

  void _onUp(int pointer) {
    if (_pointer != pointer) {
      return;
    }

    setState(() => _pointer = null);
    widget.onRelease();
  }
}
