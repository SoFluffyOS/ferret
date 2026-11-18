import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/models/models.dart';
import 'package:media/ui/widgets/artwork_view.dart';
import 'package:media/ui/widgets/progress_line.dart';
import 'package:media/ui/widgets/transport_button.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What another device plays: artwork, title, progress, controls and
/// "Continue here".
class NowPlayingCard extends StatelessWidget {
  const NowPlayingCard({
    super.key,
    required this.player,
    required this.now,
    required this.continuing,
    required this.continueKeepsPosition,
    this.picker,
    this.notice,
    this.onToggle,
    this.onNext,
    this.onPrevious,
    this.onSeek,
    this.onContinue,
  });

  final RemotePlayer player;
  final int Function() now;
  final bool continuing;
  final bool continueKeepsPosition;

  /// Chips to pick another player, when there are several.
  final Widget? picker;
  final Widget? notice;
  final VoidCallback? onToggle;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final ValueChanged<int>? onSeek;

  /// Null when the item can't be opened here.
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.mediaL10n;
    final item = player.player;
    final heading = switch (player.isPlaying) {
      true => l10n.nowPlayingOn(player.deviceName),
      false => l10n.pausedOn(player.deviceName),
    };
    final details = [
      item.artist,
      item.appName,
    ].where((part) => part.isNotEmpty).join(' · ');
    final subtitle = [
      heading,
      details,
    ].where((part) => part.isNotEmpty).join('\n');
    final continueLabel = switch (continuing) {
      true => l10n.continueOpening,
      false => l10n.continueHere,
    };

    return FeatureCard(
      icon: LucideIcons.music,
      title: item.title,
      subtitle: subtitle,
      trailing: ArtworkView(artwork: player.artwork, size: Spacing.d56),
      children: [
        if (picker case final picker?) ...[picker, Spacing.v8],
        ProgressLine(
          positionAt: player.positionAt,
          now: now,
          durationMs: player.durationMs,
          playing: player.isPlaying,
          onSeek: onSeek,
        ),
        Spacing.v8,
        Row(
          children: [
            TransportButton(
              icon: LucideIcons.skipBack,
              tooltip: l10n.previous,
              onPressed: onPrevious,
            ),
            Spacing.h8,
            TransportButton(
              icon: switch (player.isPlaying) {
                true => LucideIcons.pause,
                false => LucideIcons.play,
              },
              tooltip: switch (player.isPlaying) {
                true => l10n.pause,
                false => l10n.play,
              },
              onPressed: onToggle,
              prominent: true,
            ),
            Spacing.h8,
            TransportButton(
              icon: LucideIcons.skipForward,
              tooltip: l10n.next,
              onPressed: onNext,
            ),
          ],
        ),
        if (notice case final notice?) ...[Spacing.v8, notice],
      ],
      actions: [
        if (onContinue != null)
          Button(
            variant: .primary,
            label: continueLabel,
            tooltip: switch (continueKeepsPosition) {
              true => null,
              false => l10n.continueFromStart,
            },
            icon: Icon(LucideIcons.monitorUp, size: Spacing.d16),
            enable: !continuing,
            onPressed: onContinue,
          ),
      ],
    );
  }
}
