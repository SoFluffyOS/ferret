import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/onboarding/onboarding_layout.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The end: who is connected, and three things to try first, written for
/// this platform.
class ReadyStep extends StatelessWidget {
  const ReadyStep({
    super.key,
    required this.total,
    required this.pairedName,
    required this.onFinish,
  });

  final int total;

  /// Null when pairing was left for later.
  final String? pairedName;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final body = switch (pairedName) {
      final name? => l10n.onboardReadyBodyPaired(name),
      null => l10n.onboardReadyBodyLater,
    };
    final isPhone = Platform.isAndroid || Platform.isIOS;
    final tips = [
      (LucideIcons.clipboard, l10n.onboardTipCopy),
      switch (isPhone) {
        true => (LucideIcons.share2, l10n.onboardTipSharePhone),
        false => (LucideIcons.download, l10n.onboardTipDropComputer),
      },
      if (Platform.isMacOS)
        (LucideIcons.arrowLeftRight, l10n.onboardTipMenubar),
      if (Platform.isWindows || Platform.isLinux)
        (LucideIcons.arrowLeftRight, l10n.onboardTipTray),
      if (Platform.isAndroid) (LucideIcons.bell, l10n.onboardTipAndroid),
      (LucideIcons.sparkles, l10n.onboardTipMore),
    ];

    return OnboardingLayout(
      step: total,
      total: total,
      icon: LucideIcons.partyPopper,
      title: l10n.onboardReadyTitle,
      body: body,
      actions: [
        Button(
          variant: .primary,
          label: l10n.onboardFinish,
          onPressed: onFinish,
        ),
      ],
      child: Column(
        children: [
          for (final (icon, text) in tips)
            Padding(
              padding: EdgeInsets.only(bottom: Spacing.d8),
              child: SurfaceCard(
                child: Row(
                  children: [
                    Icon(icon, size: Spacing.d18, color: palette.accent),
                    Spacing.h12,
                    Expanded(
                      child: Text(
                        text,
                        style: typography.body2.copyWith(color: palette.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
