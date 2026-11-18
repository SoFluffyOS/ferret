import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

enum StatusTone { good, warning, info }

/// One line of status with an icon that says whether it is fine.
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.text, required this.tone});

  final String text;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final (icon, color) = switch (tone) {
      .good => (LucideIcons.circleCheck, palette.success),
      .warning => (LucideIcons.triangleAlert, palette.danger),
      .info => (LucideIcons.info, palette.mutedText),
    };

    return Row(
      crossAxisAlignment: .start,
      children: [
        Icon(icon, size: Spacing.d16, color: color),
        Spacing.h8,
        Expanded(
          child: Text(
            text,
            style: typography.base2.copyWith(color: palette.text),
          ),
        ),
      ],
    );
  }
}
