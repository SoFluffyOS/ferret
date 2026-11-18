import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A feature's health with one device: its icon tinted by how it is doing.
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
      .needsAttention => const Color(0xFFFF9F0A),
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
        padding: EdgeInsets.only(right: Spacing.d6),
        child: Icon(icon, size: Spacing.d14, color: color),
      ),
    );
  }
}
