import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A feature's health with one device, as a small labelled chip: a coloured
/// dot and the feature's name, such as "● Clipboard".
class FeatureChip extends StatelessWidget {
  const FeatureChip({
    super.key,
    required this.icon,
    required this.label,
    required this.health,
  });

  final IconData icon;
  final String label;
  final FeatureHealth health;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch (health.state) {
      .ok => palette.success,
      .needsAttention => palette.warning,
      .failing => palette.danger,
      .off => palette.mutedText,
    };
    final tooltip = switch (health.reason.isEmpty) {
      true => label,
      false => '$label: ${health.reason}',
    };

    return FluffyTooltip(
      message: tooltip,
      child: Padding(
        padding: EdgeInsets.only(right: Spacing.d8, bottom: Spacing.d4),
        child: Row(
          mainAxisSize: .min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color, shape: .circle),
              child: SizedBox.square(dimension: Spacing.d6),
            ),
            Spacing.horizontal(Spacing.d4),
            Text(
              label,
              style: context.fluffyTheme.typography.caption2.copyWith(
                color: palette.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
