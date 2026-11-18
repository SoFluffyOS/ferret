import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The target that took a drop, turned into how sending to it goes:
/// a progress bar, then a check, or what went wrong.
class DropProgressCard extends StatelessWidget {
  const DropProgressCard({
    super.key,
    required this.icon,
    required this.name,
    required this.fileCount,
    required this.phase,
  });

  final IconData icon;
  final String name;
  final int fileCount;
  final DropPhase phase;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final detail = switch (phase) {
      DropFailed(:final reason) when reason.isNotEmpty => reason,
      DropFailed() => l10n.dropFailedDetail,
      _ => l10n.dropFileCount(fileCount),
    };

    return SurfaceCard(
      padding: EdgeInsets.all(Spacing.d16),
      child: Row(
        children: [
          Icon(icon, size: Spacing.d24, color: palette.text),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text(
                  name,
                  style: typography.base1.copyWith(
                    color: palette.text,
                    fontWeight: .w600,
                  ),
                  overflow: .ellipsis,
                ),
                Spacing.vertical(Spacing.d2),
                Text(
                  detail,
                  style: typography.caption1.copyWith(
                    color: palette.mutedText,
                  ),
                ),
                if (phase case DropSending(:final fraction)) ...[
                  Spacing.v8,
                  _ProgressBar(fraction: fraction),
                ],
              ],
            ),
          ),
          if (phase is DropSent) ...[
            Spacing.h12,
            Icon(
              LucideIcons.circleCheck,
              size: Spacing.d24,
              color: palette.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Spacing.d2),
      child: SizedBox(
        height: Spacing.d4,
        child: Stack(
          fit: .expand,
          children: [
            ColoredBox(color: palette.background),
            FractionallySizedBox(
              alignment: .centerLeft,
              widthFactor: fraction.clamp(0, 1).toDouble(),
              child: ColoredBox(color: palette.accent),
            ),
          ],
        ),
      ),
    );
  }
}
