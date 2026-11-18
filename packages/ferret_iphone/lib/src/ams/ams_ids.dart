/// What AMS reports about (EntityID).
enum AmsEntity { player, queue, track }

/// PlayerAttributeID.
abstract final class AmsPlayerAttribute {
  /// The app's name, such as "Music".
  static const name = 0;

  /// `state,rate,elapsed`, such as `1,1.0,12.5`.
  static const playbackInfo = 1;

  /// 0 to 1 as text.
  static const volume = 2;

  static const all = [name, playbackInfo, volume];
}

/// QueueAttributeID.
abstract final class AmsQueueAttribute {
  static const index = 0;
  static const count = 1;
  static const shuffleMode = 2;
  static const repeatMode = 3;

  static const all = [index, count, shuffleMode, repeatMode];
}

/// TrackAttributeID.
abstract final class AmsTrackAttribute {
  static const artist = 0;
  static const album = 1;
  static const title = 2;

  /// Seconds as text.
  static const duration = 3;

  static const all = [artist, album, title, duration];
}

/// What the player is doing (PlaybackState).
enum AmsPlaybackState {
  paused,
  playing,
  rewinding,
  fastForwarding;

  static AmsPlaybackState fromId(int? id) {
    if (id == null || id < 0 || id >= values.length) {
      return paused;
    }

    return values[id];
  }
}

/// What the iPhone's player can be told (RemoteCommandID). The index is the
/// command's id.
enum AmsCommand {
  play,
  pause,
  togglePlayPause,
  nextTrack,
  previousTrack,
  volumeUp,
  volumeDown,
  advanceRepeatMode,
  advanceShuffleMode,
  skipForward,
  skipBackward,
  likeTrack,
  dislikeTrack,
  bookmarkTrack;

  int get id => index;

  static AmsCommand? fromId(int id) {
    if (id < 0 || id >= values.length) {
      return null;
    }

    return values[id];
  }
}

/// ATT error codes AMS answers a write with.
abstract final class AmsError {
  /// The iPhone isn't in a state to do that, such as no player open.
  static const invalidState = 0xA0;
  static const invalidCommand = 0xA1;
  static const absentAttribute = 0xA2;
}
