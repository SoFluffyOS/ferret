import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/models/models.dart';
import 'package:media/view_models/view_models.dart';

/// Media's line in Home's Activity list: what plays, or is paused, on
/// another device, with play/pause and next.
abstract final class MediaActivity {
  static const itemId = 'media.now_playing';

  /// One pinned line for the player [model] has selected, or nothing while
  /// nothing plays. [onTap] opens the full controls.
  static List<ActivityItem> items(
    MediaLocalizations l10n,
    MediaViewModel model, {
    VoidCallback? onTap,
  }) {
    final player = model.selected;
    if (player == null) {
      return const [];
    }

    final canToggle =
        player.can(.MEDIA_ACTION_TOGGLE) ||
        player.can(.MEDIA_ACTION_PLAY) ||
        player.can(.MEDIA_ACTION_PAUSE);
    final artist = player.player.artist;

    return [
      ActivityItem(
        id: itemId,
        deviceId: player.deviceId,
        icon: LucideIcons.music,
        title: _title(l10n, player),
        detail: switch (artist.isEmpty) {
          true => null,
          false => artist,
        },
        pinned: true,
        actions: [
          if (canToggle) _toggle(l10n, model, player),
          if (player.can(.MEDIA_ACTION_NEXT))
            ActivityAction(
              label: l10n.next,
              icon: LucideIcons.skipForward,
              onPressed: () => unawaited(model.next()),
            ),
        ],
        onTap: onTap,
      ),
    ];
  }

  static String _title(MediaLocalizations l10n, RemotePlayer player) {
    final item = player.player;
    if (item.title.isNotEmpty) {
      return '${item.title} · ${player.deviceName}';
    }

    if (item.appName.isNotEmpty) {
      return l10n.playerOn(item.appName, player.deviceName);
    }

    return switch (player.isPlaying) {
      true => l10n.nowPlayingOn(player.deviceName),
      false => l10n.pausedOn(player.deviceName),
    };
  }

  static ActivityAction _toggle(
    MediaLocalizations l10n,
    MediaViewModel model,
    RemotePlayer player,
  ) => switch (player.isPlaying) {
    true => ActivityAction(
      label: l10n.pause,
      icon: LucideIcons.pause,
      onPressed: () => unawaited(model.togglePlay()),
    ),
    false => ActivityAction(
      label: l10n.play,
      icon: LucideIcons.play,
      onPressed: () => unawaited(model.togglePlay()),
    ),
  };
}
