import 'dart:async';

import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/models/models.dart';
import 'package:clipboard/ui/widgets/widgets.dart';
import 'package:clipboard/view_models/clipboard_view_model.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The last clips that can be copied again, each with Copy. A clip from a
/// device whose previews are hidden here shows where it came from, never
/// what it holds.
class RecentClipsFrame extends StatelessWidget {
  const RecentClipsFrame({super.key, required this.showsPreviewsFrom});

  final bool Function(String deviceId) showsPreviewsFrom;

  static const _previewLength = 80;

  @override
  Widget build(BuildContext context) {
    final clips = context.select<ClipboardViewModel, List<ClipEntry>>(
      (viewModel) => viewModel.recentClips,
    );
    final copiedId = context.select<ClipboardViewModel, String?>(
      (viewModel) => viewModel.copiedId,
    );
    final viewModel = context.read<ClipboardViewModel>();
    final l10n = context.clipboardL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final note = Text(
      l10n.recentClipsNote,
      style: typography.caption1.copyWith(color: palette.mutedText),
    );

    if (clips.isEmpty) {
      return Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
        children: [
          Text(l10n.recentClipsEmpty, style: typography.base2),
          Spacing.v8,
          note,
        ],
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        GroupedCard(
          separatorIndent: PageInsets.row + IconTile.size + Spacing.d12,
          children: [
            for (final clip in clips)
              _row(l10n, viewModel, clip, isCopied: clip.id == copiedId),
          ],
        ),
        Spacing.v8,
        note,
      ],
    );
  }

  Widget _row(
    ClipboardLocalizations l10n,
    ClipboardViewModel viewModel,
    ClipEntry clip, {
    required bool isCopied,
  }) {
    final from = clip.deviceNames.firstOrNull ?? '';
    final source = switch (clip.direction) {
      .received => l10n.recentFrom(from),
      .sent => l10n.recentCopiedHere,
    };
    final isHidden = switch ((clip.direction, clip.deviceIds)) {
      (.received, [final deviceId, ...]) => !showsPreviewsFrom(deviceId),
      _ => false,
    };

    return RecentClipRow(
      icon: switch (clip.item.kind) {
        .CLIP_KIND_IMAGE => LucideIcons.image,
        .CLIP_KIND_URL => LucideIcons.link,
        _ => LucideIcons.type,
      },
      title: switch (isHidden) {
        true => l10n.activityCopiedOn(from),
        false => _preview(l10n, clip),
      },
      subtitle: switch (isHidden) {
        true => l10n.recentHidden,
        false => source,
      },
      copyLabel: switch (isCopied) {
        true => l10n.copied,
        false => l10n.copy,
      },
      isCopied: isCopied,
      onCopy: () => unawaited(viewModel.copyAgain(clip)),
    );
  }

  String _preview(ClipboardLocalizations l10n, ClipEntry clip) {
    if (clip.isImage) {
      return l10n.imageLabel;
    }

    final text = clip.item.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= _previewLength) {
      return text;
    }

    return '${text.substring(0, _previewLength)}…';
  }
}
