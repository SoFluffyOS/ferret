import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Says Ferret is paused, until when, and resumes it in one tap.
class PauseBanner extends StatelessWidget {
  const PauseBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final paused = context.select<PauseController, bool>(
      (controller) => controller.isPaused,
    );
    final until = context.select<PauseController, DateTime?>(
      (controller) => controller.until,
    );
    if (!paused) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final subtitle = switch (until) {
      final until? => l10n.pausedUntil(_time(until)),
      null => l10n.pausedUntilResume,
    };

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        child: Row(
          children: [
            Icon(
              LucideIcons.circlePause,
              size: Spacing.d20,
              color: palette.accent,
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    l10n.pausedTitle,
                    style: typography.base1.copyWith(color: palette.text),
                  ),
                  Text(
                    subtitle,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Button(
              variant: .primary,
              label: l10n.resume,
              onPressed: () => context.read<PauseController>().resume(),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
