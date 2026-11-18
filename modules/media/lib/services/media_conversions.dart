import 'dart:typed_data';

import 'package:ferret_media/ferret_media.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/media.dart';

/// Moves between the platform plugin's types and the wire messages.
abstract final class MediaConversions {
  /// [info] as a wire player, without the artwork bytes.
  static MediaPlayer toWire(PlayerInfo info) => MediaPlayer(
    playerId: info.id,
    appId: info.appId,
    appName: info.appName,
    title: info.title,
    artist: info.artist,
    album: info.album,
    artworkId: switch (info.artwork) {
      final artwork? when artwork.isNotEmpty => artworkId(artwork),
      _ => '',
    },
    durationMs: Int64(_positive(info.durationMs)),
    positionMs: Int64(_positive(info.positionMs)),
    positionAtMs: Int64(_positive(info.positionAtMs)),
    status: statusToWire(info.status),
    playbackRate: info.playbackRate,
    contentUri: info.contentUri ?? '',
    lastActiveAtMs: Int64(_positive(info.lastActiveAtMs)),
    actions: [for (final action in info.actions) actionToWire(action)],
    volume: info.volume,
  );

  /// A short fingerprint of [bytes] (64-bit FNV-1a), so the same image is
  /// sent once per session.
  static String artworkId(Uint8List bytes) {
    var hash = Int64.parseHex('cbf29ce484222325');
    final prime = Int64.parseHex('100000001b3');
    for (final byte in bytes) {
      hash = (hash ^ byte) * prime;
    }

    return '${hash.toHexString()}-${bytes.length}';
  }

  static MediaPlaybackStatus statusToWire(PlayerStatus status) =>
      switch (status) {
        .playing => .MEDIA_PLAYBACK_STATUS_PLAYING,
        .paused => .MEDIA_PLAYBACK_STATUS_PAUSED,
        .buffering => .MEDIA_PLAYBACK_STATUS_BUFFERING,
        .stopped => .MEDIA_PLAYBACK_STATUS_STOPPED,
      };

  static MediaAction actionToWire(PlayerAction action) => switch (action) {
    .play => .MEDIA_ACTION_PLAY,
    .pause => .MEDIA_ACTION_PAUSE,
    .toggle => .MEDIA_ACTION_TOGGLE,
    .next => .MEDIA_ACTION_NEXT,
    .previous => .MEDIA_ACTION_PREVIOUS,
    .seek => .MEDIA_ACTION_SEEK,
    .setVolume => .MEDIA_ACTION_SET_VOLUME,
  };

  static PlayerAction? actionFromWire(MediaAction action) => switch (action) {
    .MEDIA_ACTION_PLAY => .play,
    .MEDIA_ACTION_PAUSE => .pause,
    .MEDIA_ACTION_TOGGLE => .toggle,
    .MEDIA_ACTION_NEXT => .next,
    .MEDIA_ACTION_PREVIOUS => .previous,
    .MEDIA_ACTION_SEEK => .seek,
    .MEDIA_ACTION_SET_VOLUME => .setVolume,
    _ => null,
  };

  static int _positive(int value) => switch (value < 0) {
    true => 0,
    false => value,
  };
}
