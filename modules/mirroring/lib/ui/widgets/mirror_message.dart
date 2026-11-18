import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What the mirror page says when there is no picture: where things stand
/// in plain words, and a button for what to do next.
class MirrorMessage extends StatelessWidget {
  const MirrorMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.tone = .muted,
    this.actionLabel,
    this.onAction,
    this.secondLabel,
    this.onSecond,
  });

  final IconData icon;
  final String title;
  final String body;
  final FeatureTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The other way out, such as "Don't allow", next to the main action.
  final String? secondLabel;
  final VoidCallback? onSecond;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final iconColor = switch (tone) {
      .accent => palette.accent,
      .danger => palette.danger,
      .warning => palette.warning,
      .success => palette.success,
      .normal => palette.text,
      .muted => palette.mutedText,
    };

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(Spacing.d24),
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(icon, size: Spacing.d32, color: iconColor),
            Spacing.v12,
            Text(
              title,
              textAlign: .center,
              style: typography.base1.copyWith(color: palette.text),
            ),
            Spacing.v4,
            Text(
              body,
              textAlign: .center,
              style: typography.caption1.copyWith(color: palette.mutedText),
            ),
            if ((actionLabel, onAction) case (final label?, final action?)) ...[
              Spacing.v16,
              Wrap(
                alignment: .center,
                spacing: Spacing.d8,
                runSpacing: Spacing.d8,
                children: [
                  if ((secondLabel, onSecond) case (
                    final otherLabel?,
                    final otherAction?,
                  ))
                    Button(
                      variant: .ghost,
                      label: otherLabel,
                      onPressed: otherAction,
                    ),
                  Button(variant: .primary, label: label, onPressed: action),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
