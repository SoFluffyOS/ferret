import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A plain-words problem under the controls, with a way to close it.
class NoticeLine extends StatelessWidget {
  const NoticeLine({
    super.key,
    required this.text,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final String text;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      crossAxisAlignment: .start,
      children: [
        Icon(LucideIcons.circleAlert, size: Spacing.d16, color: palette.danger),
        Spacing.h8,
        Expanded(
          child: Text(
            text,
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: palette.text,
            ),
          ),
        ),
        Tappable(
          tooltip: dismissLabel,
          onTap: onDismiss,
          child: Icon(
            LucideIcons.x,
            size: Spacing.d16,
            color: palette.mutedText,
          ),
        ),
      ],
    );
  }
}
