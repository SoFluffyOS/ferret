import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The three steps to allow restricted settings on Android 13+, with a
/// button to the first one.
class RestrictedGuide extends StatelessWidget {
  const RestrictedGuide({super.key, required this.onOpenAppInfo});

  final VoidCallback onOpenAppInfo;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;
    final steps = [
      l10n.restrictedStepOne,
      l10n.restrictedStepTwo,
      l10n.restrictedStepThree,
    ];

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(
          l10n.restrictedTitle,
          style: typography.base1.copyWith(color: palette.text),
        ),
        Spacing.v4,
        Text(
          l10n.restrictedBody,
          style: typography.body2.copyWith(color: palette.mutedText),
        ),
        Spacing.v8,
        for (final (index, step) in steps.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: Spacing.d4),
            child: Row(
              crossAxisAlignment: .start,
              children: [
                SizedBox(
                  width: Spacing.d20,
                  child: Text(
                    '${index + 1}.',
                    style: typography.body2.copyWith(color: palette.accent),
                  ),
                ),
                Expanded(
                  child: Text(
                    step,
                    style: typography.body2.copyWith(color: palette.text),
                  ),
                ),
              ],
            ),
          ),
        Spacing.v8,
        Button(
          variant: .secondary,
          label: l10n.openAppInfo,
          onPressed: onOpenAppInfo,
        ),
      ],
    );
  }
}
