import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One round media control, such as play or next. Greyed out when
/// [onPressed] is null.
class TransportButton extends StatelessWidget {
  const TransportButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.prominent = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null;
    final color = switch ((enabled, prominent)) {
      (false, _) => palette.mutedText,
      (true, true) => palette.background,
      (true, false) => palette.text,
    };
    final fill = switch ((enabled, prominent)) {
      (true, true) => palette.accent,
      _ => palette.background,
    };
    final size = switch (prominent) {
      true => Spacing.d40,
      false => Spacing.d32,
    };

    return Tappable(
      tooltip: tooltip,
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, shape: .circle),
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: Spacing.d16, color: color),
        ),
      ),
    );
  }
}
