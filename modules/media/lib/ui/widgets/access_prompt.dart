import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Why a feature needs a permission, with the button that fixes it.
class AccessPrompt extends StatelessWidget {
  const AccessPrompt({
    super.key,
    required this.text,
    required this.actionLabel,
    required this.onAction,
    required this.checkAgainLabel,
    required this.onCheckAgain,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;
  final String checkAgainLabel;
  final VoidCallback onCheckAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          text,
          style: context.fluffyTheme.typography.body2.copyWith(
            color: context.palette.text,
          ),
        ),
        Spacing.v8,
        Wrap(
          spacing: Spacing.d8,
          runSpacing: Spacing.d8,
          children: [
            Button(
              mainAxisSize: .min,
              variant: .primary,
              label: actionLabel,
              onPressed: onAction,
            ),
            Button(
              mainAxisSize: .min,
              variant: .ghost,
              label: checkAgainLabel,
              onPressed: onCheckAgain,
            ),
          ],
        ),
      ],
    );
  }
}
