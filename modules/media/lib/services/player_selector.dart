import 'package:media/models/models.dart';

/// The player the person picked, and when.
class PlayerPick {
  const PlayerPick(this.key, this.atMs);

  final PlayerKey key;
  final int atMs;
}

/// Picks the player to show when there are several: the one the person
/// picked, until another player becomes active after that; otherwise the
/// last active one, preferring players that are playing.
abstract final class PlayerSelector {
  static RemotePlayer? select(List<RemotePlayer> players, {PlayerPick? pick}) {
    if (players.isEmpty) {
      return null;
    }

    if (pick != null) {
      final picked = _find(players, pick.key);
      final newer = players.any(
        (player) =>
            player.key != pick.key &&
            player.isPlaying &&
            player.lastActiveAtMs > pick.atMs,
      );
      if (picked != null && !newer) {
        return picked;
      }
    }

    final ranked = [...players]..sort(_compare);
    return ranked.first;
  }

  static RemotePlayer? _find(List<RemotePlayer> players, PlayerKey key) {
    for (final player in players) {
      if (player.key == key) {
        return player;
      }
    }

    return null;
  }

  static int _compare(RemotePlayer a, RemotePlayer b) {
    if (a.isPlaying != b.isPlaying) {
      return switch (a.isPlaying) {
        true => -1,
        false => 1,
      };
    }

    return b.lastActiveAtMs.compareTo(a.lastActiveAtMs);
  }
}
