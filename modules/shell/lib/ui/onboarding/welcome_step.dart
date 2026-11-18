import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/onboarding/onboarding_layout.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What Ferret does, in four lines, and the privacy promise.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.total, required this.onNext});

  final int total;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final points = [
      (LucideIcons.monitorSmartphone, l10n.onboardPointContinue),
      (LucideIcons.clipboard, l10n.onboardPointClipboard),
      (LucideIcons.send, l10n.onboardPointFiles),
      (LucideIcons.bell, l10n.onboardPointPhone),
    ];

    return OnboardingLayout(
      step: 1,
      total: total,
      icon: LucideIcons.arrowLeftRight,
      title: l10n.onboardWelcomeTitle,
      body: l10n.onboardWelcomeBody,
      actions: [
        Button(variant: .primary, label: l10n.onboardStart, onPressed: onNext),
      ],
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          for (final (icon, text) in points)
            Padding(
              padding: EdgeInsets.only(bottom: Spacing.d12),
              child: Row(
                children: [
                  Icon(icon, size: Spacing.d20, color: palette.text),
                  Spacing.h12,
                  Expanded(
                    child: Text(
                      text,
                      style: typography.base1.copyWith(color: palette.text),
                    ),
                  ),
                ],
              ),
            ),
          Spacing.v8,
          Row(
            children: [
              Icon(
                LucideIcons.lock,
                size: Spacing.d14,
                color: palette.mutedText,
              ),
              Spacing.h8,
              Expanded(
                child: Text(
                  l10n.welcomePrivacy,
                  style: typography.caption1.copyWith(color: palette.mutedText),
                ),
              ),
            ],
          ),
          Spacing.v4,
          Text(
            l10n.welcomePlatforms,
            style: typography.caption2.copyWith(color: palette.mutedText),
          ),
        ],
      ),
    );
  }
}
