import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One button of the mirror toolbar: an icon with its name as a tooltip,
/// or with the name next to it where there is room for words.
class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.name,
    required this.onTap,
    this.tooltip,
    this.showName = false,
    this.tone = .normal,
    this.child,
  });

  final IconData icon;
  final String name;
  final VoidCallback? onTap;

  /// The name with its shortcut. Defaults to [name].
  final String? tooltip;

  /// Shows [name] next to the icon.
  final bool showName;
  final FeatureTone tone;

  /// Drawn in place of the icon, such as the quality mark.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (tone) {
      .danger => palette.danger,
      .muted => palette.mutedText,
      _ => palette.text,
    };
    final mark = SizedBox.square(
      dimension: Spacing.d28,
      child: Center(
        child: child ?? Icon(icon, size: Spacing.d16, color: color),
      ),
    );

    return Tappable(
      tooltip: tooltip ?? name,
      onTap: onTap,
      enableHover: true,
      enableHoverOverlay: true,
      hoverOverlayBorderRadius: Corners.capsule,
      child: switch (showName) {
        false => mark,
        true => Padding(
          padding: EdgeInsets.only(right: Spacing.d8),
          child: Row(
            mainAxisSize: .min,
            children: [
              mark,
              Spacing.h4,
              Text(
                name,
                // The tooltip already says the name once.
                semanticsLabel: switch (tooltip) {
                  null => '',
                  _ => null,
                },
                style: context.fluffyTheme.typography.base2.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ),
      },
    );
  }
}
