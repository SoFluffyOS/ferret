import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Where a setup step stands.
enum SetupStepState { done, current, later }

/// One numbered step of a setup, with its button while it is the one to do.
class SetupStepRow extends StatelessWidget {
  const SetupStepRow({
    super.key,
    required this.title,
    required this.body,
    required this.state,
    required this.buttonLabel,
    required this.onPressed,
    this.enabled = true,
  });

  final String title;
  final String body;
  final SetupStepState state;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final isCurrent = state == .current;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: typography.base1.copyWith(
                    color: switch (state) {
                      .later => palette.mutedText,
                      _ => palette.text,
                    },
                  ),
                ),
              ),
              if (state == .done) ...[
                Spacing.h8,
                Icon(
                  LucideIcons.circleCheck,
                  size: Spacing.d16,
                  color: palette.success,
                ),
              ],
            ],
          ),
          if (isCurrent) ...[
            Spacing.vertical(Spacing.d2),
            Text(
              body,
              style: typography.caption1.copyWith(color: palette.mutedText),
            ),
            Spacing.v8,
            Button(
              mainAxisSize: .min,
              variant: .primary,
              label: buttonLabel,
              enable: enabled,
              onPressed: onPressed,
            ),
          ],
        ],
      ),
    );
  }
}
