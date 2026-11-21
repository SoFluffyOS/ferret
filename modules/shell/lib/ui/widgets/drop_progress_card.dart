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
    this.folderCount = 0,
    this.kind = .files,
    this.isFlat = false,
  });

  final IconData icon;
  final String name;

  /// Everything dropped, folders included.
  final int fileCount;

  /// How many of [fileCount] are folders.
  final int folderCount;

  /// What was dropped: files, text or a link.
  final DropKind kind;
  final DropPhase phase;

  /// Drawn straight on what holds it, without a card of its own: inside a
  /// panel that is already the card, a second fill would need a corner
  /// too small to read as one.
  final bool isFlat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final detail = switch (phase) {
      DropFailed(:final reason) when reason.isNotEmpty => reason,
      DropFailed() => l10n.dropFailedDetail,
      _ => switch (kind) {
        .files => _items(l10n),
        .text => l10n.dropKindText,
        .link => l10n.dropKindLink,
      },
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: _card(context, detail),
    );
  }

  /// "3 files", "1 folder" or "2 files and 1 folder".
  String _items(ShellLocalizations l10n) {
    final files = fileCount - folderCount;

    return switch ((files, folderCount)) {
      (_, 0) => l10n.dropFileCount(files),
      (0, _) => l10n.dropFolderCount(folderCount),
      _ => l10n.dropFilesAndFolders(
        l10n.dropFileCount(files),
        l10n.dropFolderCount(folderCount),
      ),
    };
  }

  Widget _card(BuildContext context, String detail) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    final row = Row(
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
                FluffyProgressBar(
                  value: fraction.clamp(0, 1).toDouble(),
                  color: context.palette.accent,
                  backgroundColor: switch (isFlat) {
                    true => palette.surface,
                    false => palette.background,
                  },
                ),
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
    );

    if (isFlat) {
      return row;
    }

    return SurfaceCard(padding: EdgeInsets.all(Spacing.d16), child: row);
  }
}
