import 'package:flutter/widgets.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/models/models.dart';
import 'package:media/ui/frames/notice_text.dart';
import 'package:media/ui/widgets/widgets.dart';
import 'package:media/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card for media on other devices. Shows nothing while nothing
/// plays.
class NowPlayingFrame extends StatelessWidget {
  const NowPlayingFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.select<MediaViewModel, RemotePlayer?>(
      (model) => model.selected,
    );
    final players = context.select<MediaViewModel, List<RemotePlayer>>(
      (model) => model.players,
    );
    final notice = context.select<MediaViewModel, MediaNotice?>(
      (model) => model.notice,
    );
    final continuing = context.select<MediaViewModel, bool>(
      (model) => model.isContinuing,
    );
    final canContinue = context.select<MediaViewModel, bool>(
      (model) => model.canContinue,
    );
    final keepsPosition = context.select<MediaViewModel, bool>(
      (model) => model.continueKeepsPosition,
    );
    if (player == null) {
      return const SizedBox.shrink();
    }

    final model = context.read<MediaViewModel>();
    final l10n = context.mediaL10n;
    final canToggle =
        player.can(.MEDIA_ACTION_TOGGLE) ||
        player.can(.MEDIA_ACTION_PLAY) ||
        player.can(.MEDIA_ACTION_PAUSE);

    return NowPlayingCard(
      player: player,
      now: model.now,
      continuing: continuing,
      continueKeepsPosition: keepsPosition,
      picker: _picker(context, model, players, player),
      notice: switch (notice) {
        final notice? => NoticeLine(
          text: l10n.noticeText(notice),
          dismissLabel: l10n.tryAgain,
          onDismiss: model.dismissNotice,
        ),
        null => null,
      },
      onToggle: _when(canToggle, model.togglePlay),
      onNext: _when(player.can(.MEDIA_ACTION_NEXT), model.next),
      onPrevious: _when(player.can(.MEDIA_ACTION_PREVIOUS), model.previous),
      onSeek: switch (player.can(.MEDIA_ACTION_SEEK)) {
        true => model.seekTo,
        false => null,
      },
      onContinue: _when(canContinue, model.continueHere),
    );
  }

  Widget? _picker(
    BuildContext context,
    MediaViewModel model,
    List<RemotePlayer> players,
    RemotePlayer selected,
  ) {
    if (players.length < 2) {
      return null;
    }

    final l10n = context.mediaL10n;
    return SingleChildScrollView(
      scrollDirection: .horizontal,
      child: Row(
        children: [
          for (final player in players) ...[
            PlayerChip(
              label: l10n.playerOn(player.player.appName, player.deviceName),
              selected: player.key == selected.key,
              onTap: () => model.select(player.key),
            ),
            Spacing.h6,
          ],
        ],
      ),
    );
  }

  static VoidCallback? _when(bool enabled, Future<void> Function() action) {
    if (!enabled) {
      return null;
    }

    return () => action();
  }
}
