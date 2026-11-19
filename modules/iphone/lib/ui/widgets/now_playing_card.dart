import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/ui/widgets/playback_progress.dart';
import 'package:iphone/ui/widgets/transport_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Now playing on iPhone": the track, where it is, and the controls the
/// iPhone accepts right now.
class NowPlayingCard extends StatelessWidget {
  const NowPlayingCard({
    super.key,
    required this.media,
    required this.deviceName,
    required this.onCommand,
    this.commandFailed = false,
    this.now,
  });

  final AmsState media;
  final String deviceName;
  final ValueChanged<AmsCommand> onCommand;

  /// The last control didn't reach the iPhone.
  final bool commandFailed;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.iphoneL10n;
    final palette = context.palette;
    final device = switch (deviceName.isEmpty) {
      true => l10n.yourIphone,
      false => deviceName,
    };
    final heading = switch (media.isPlaying) {
      true => l10n.nowPlayingOn(device),
      false => l10n.pausedOn(device),
    };
    final details = [
      media.artist,
      media.playerName,
    ].where((part) => part.isNotEmpty).join(' · ');
    final subtitle = [
      heading,
      details,
    ].where((part) => part.isNotEmpty).join('\n');
    final title = switch (media.title.isEmpty) {
      true => media.artist,
      false => media.title,
    };

    return FeatureCard(
      icon: LucideIcons.music,
      title: title,
      subtitle: subtitle,
      children: [
        PlaybackProgress(media: media, now: now),
        Spacing.v8,
        Row(
          children: [
            TransportButton(
              icon: LucideIcons.skipBack,
              tooltip: l10n.previous,
              onPressed: _handler(.previousTrack),
            ),
            Spacing.h8,
            TransportButton(
              icon: switch (media.isPlaying) {
                true => LucideIcons.pause,
                false => LucideIcons.play,
              },
              tooltip: switch (media.isPlaying) {
                true => l10n.pause,
                false => l10n.play,
              },
              onPressed: _handler(.togglePlayPause),
              prominent: true,
            ),
            Spacing.h8,
            TransportButton(
              icon: LucideIcons.skipForward,
              tooltip: l10n.next,
              onPressed: _handler(.nextTrack),
            ),
            const Spacer(),
            TransportButton(
              icon: LucideIcons.volume1,
              tooltip: l10n.volumeDown,
              onPressed: _handler(.volumeDown),
            ),
            Spacing.h8,
            TransportButton(
              icon: LucideIcons.volume2,
              tooltip: l10n.volumeUp,
              onPressed: _handler(.volumeUp),
            ),
          ],
        ),
        if (commandFailed) ...[
          Spacing.v8,
          Text(
            l10n.commandFailed(device, ThisComputer.here),
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: palette.danger,
            ),
          ),
        ],
      ],
    );
  }

  /// Null greys the button out when the iPhone says the command won't work,
  /// such as "next" on the last track.
  VoidCallback? _handler(AmsCommand command) {
    if (!media.supports(command)) {
      return null;
    }

    return () => onCommand(command);
  }
}
