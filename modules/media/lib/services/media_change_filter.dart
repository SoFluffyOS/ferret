import 'package:media/models/models.dart';
import 'package:protocol/media.dart';

/// Decides whether new local player state is worth sending. A position that
/// moved as expected is not: the receiver extrapolates it.
abstract final class MediaChangeFilter {
  /// How far the reported position may drift from the extrapolated one
  /// before it counts as a seek.
  static const seekTolerance = Duration(seconds: 2);

  static bool isSignificant(
    List<MediaPlayer> previous,
    List<MediaPlayer> next,
  ) {
    if (previous.length != next.length) {
      return true;
    }

    final byId = {for (final player in previous) player.playerId: player};
    for (final player in next) {
      final before = byId[player.playerId];
      if (before == null || _changed(before, player)) {
        return true;
      }
    }

    return false;
  }

  static bool _changed(MediaPlayer before, MediaPlayer after) {
    final sameItem =
        before.title == after.title &&
        before.artist == after.artist &&
        before.album == after.album &&
        before.artworkId == after.artworkId &&
        before.durationMs == after.durationMs &&
        before.contentUri == after.contentUri &&
        before.status == after.status &&
        before.playbackRate == after.playbackRate &&
        before.volume == after.volume &&
        before.appName == after.appName &&
        _sameActions(before.actions, after.actions);
    if (!sameItem) {
      return true;
    }

    final expected = PlaybackPosition.at(
      nowMs: after.positionAtMs.toInt(),
      positionMs: before.positionMs.toInt(),
      positionAtMs: before.positionAtMs.toInt(),
      playing: before.status == .MEDIA_PLAYBACK_STATUS_PLAYING,
      rate: before.playbackRate,
      durationMs: before.durationMs.toInt(),
    );
    final drift = (after.positionMs.toInt() - expected).abs();
    return drift > seekTolerance.inMilliseconds;
  }

  static bool _sameActions(List<MediaAction> a, List<MediaAction> b) {
    if (a.length != b.length) {
      return false;
    }

    return a.toSet().containsAll(b);
  }
}
