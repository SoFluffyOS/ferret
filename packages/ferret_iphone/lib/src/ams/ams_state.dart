import 'package:ferret_iphone/src/ams/ams_ids.dart';
import 'package:ferret_iphone/src/ams/ams_update.dart';

/// What the iPhone is playing, built from AMS updates.
class AmsState {
  const AmsState({
    this.playerName = '',
    this.playback = .paused,
    this.rate = 0,
    this.elapsed = Duration.zero,
    this.elapsedAt,
    this.volume,
    this.artist = '',
    this.album = '',
    this.title = '',
    this.duration,
    this.queueIndex,
    this.queueCount,
    this.supported = const {},
  });

  /// The app that plays, such as "Music" or "Spotify".
  final String playerName;
  final AmsPlaybackState playback;

  /// 1 is normal speed, 0 is paused.
  final double rate;

  /// The position in the track at [elapsedAt].
  final Duration elapsed;

  /// When this computer learned [elapsed].
  final DateTime? elapsedAt;

  /// 0 to 1, or null when unknown.
  final double? volume;
  final String artist;
  final String album;
  final String title;
  final Duration? duration;
  final int? queueIndex;
  final int? queueCount;

  /// The commands the iPhone accepts right now. Empty until it says.
  final Set<AmsCommand> supported;

  bool get isPlaying => playback == .playing;

  /// Something is loaded in a player, playing or not.
  bool get hasTrack => title.isNotEmpty || artist.isNotEmpty;

  /// Whether [command] can be sent. Before the iPhone listed its commands,
  /// everything is worth a try.
  bool supports(AmsCommand command) =>
      supported.isEmpty || supported.contains(command);

  /// The position in the track at [now]: [elapsed] moved on at [rate],
  /// kept inside the track.
  Duration positionAt(DateTime now) {
    final since = elapsedAt;
    if (since == null || playback == .paused) {
      return _inTrack(elapsed);
    }

    final passed = now.difference(since).inMicroseconds * rate;
    return _inTrack(elapsed + Duration(microseconds: passed.round()));
  }

  /// This state with [update] applied. [now] stamps a new position.
  AmsState apply(AmsUpdate update, DateTime now) => switch (update.entity) {
    .player => _applyPlayer(update, now),
    .queue => _applyQueue(update),
    .track => _applyTrack(update),
  };

  AmsState withSupported(Set<AmsCommand> commands) =>
      _copy(supported: commands);

  AmsState _applyPlayer(AmsUpdate update, DateTime now) {
    if (update.attribute == AmsPlayerAttribute.name) {
      return _copy(playerName: update.value);
    }

    if (update.attribute == AmsPlayerAttribute.volume) {
      return _copy(volume: () => double.tryParse(update.value));
    }

    if (update.attribute != AmsPlayerAttribute.playbackInfo) {
      return this;
    }

    final parts = update.value.split(',');
    if (parts.length < 3) {
      return _copy(
        playback: .paused,
        rate: 0,
        elapsed: Duration.zero,
        elapsedAt: () => null,
      );
    }

    final seconds = double.tryParse(parts[2]) ?? 0;

    return _copy(
      playback: AmsPlaybackState.fromId(int.tryParse(parts[0])),
      rate: double.tryParse(parts[1]) ?? 0,
      elapsed: Duration(microseconds: (seconds * 1000000).round()),
      elapsedAt: () => now,
    );
  }

  AmsState _applyQueue(AmsUpdate update) => switch (update.attribute) {
    AmsQueueAttribute.index => _copy(
      queueIndex: () => int.tryParse(update.value),
    ),
    AmsQueueAttribute.count => _copy(
      queueCount: () => int.tryParse(update.value),
    ),
    _ => this,
  };

  AmsState _applyTrack(AmsUpdate update) => switch (update.attribute) {
    AmsTrackAttribute.artist => _copy(artist: update.value),
    AmsTrackAttribute.album => _copy(album: update.value),
    AmsTrackAttribute.title => _copy(title: update.value),
    AmsTrackAttribute.duration => _copy(
      duration: () => _seconds(update.value),
    ),
    _ => this,
  };

  Duration _inTrack(Duration position) {
    if (position.isNegative) {
      return Duration.zero;
    }

    final end = duration;
    if (end != null && position > end) {
      return end;
    }

    return position;
  }

  static Duration? _seconds(String text) {
    final seconds = double.tryParse(text);
    if (seconds == null || seconds <= 0) {
      return null;
    }

    return Duration(microseconds: (seconds * 1000000).round());
  }

  AmsState _copy({
    String? playerName,
    AmsPlaybackState? playback,
    double? rate,
    Duration? elapsed,
    DateTime? Function()? elapsedAt,
    double? Function()? volume,
    String? artist,
    String? album,
    String? title,
    Duration? Function()? duration,
    int? Function()? queueIndex,
    int? Function()? queueCount,
    Set<AmsCommand>? supported,
  }) => AmsState(
    playerName: playerName ?? this.playerName,
    playback: playback ?? this.playback,
    rate: rate ?? this.rate,
    elapsed: elapsed ?? this.elapsed,
    elapsedAt: _pick(elapsedAt, this.elapsedAt),
    volume: _pick(volume, this.volume),
    artist: artist ?? this.artist,
    album: album ?? this.album,
    title: title ?? this.title,
    duration: _pick(duration, this.duration),
    queueIndex: _pick(queueIndex, this.queueIndex),
    queueCount: _pick(queueCount, this.queueCount),
    supported: supported ?? this.supported,
  );

  static T? _pick<T>(T? Function()? change, T? current) {
    if (change == null) {
      return current;
    }

    return change();
  }
}
