import 'dart:typed_data';

import 'package:media/models/playback_position.dart';
import 'package:media/models/player_key.dart';
import 'package:protocol/media.dart';

/// A player on another device, with its times mapped onto this device's
/// clock.
class RemotePlayer {
  const RemotePlayer({
    required this.deviceId,
    required this.deviceName,
    required this.player,
    required this.positionAtMs,
    required this.lastActiveAtMs,
    this.artwork,
    this.isConnected = true,
  });

  final String deviceId;
  final String deviceName;

  /// As the device sent it, without the artwork bytes.
  final MediaPlayer player;

  /// When [MediaPlayer.positionMs] was true, on this device's clock.
  final int positionAtMs;

  /// When the player last started or changed item, on this device's clock.
  final int lastActiveAtMs;
  final Uint8List? artwork;

  /// False once the device disconnected; its last state is kept.
  final bool isConnected;

  PlayerKey get key => PlayerKey(deviceId, player.playerId);

  bool get isPlaying => player.status == .MEDIA_PLAYBACK_STATUS_PLAYING;

  int get durationMs => player.durationMs.toInt();

  bool can(MediaAction action) => player.actions.contains(action);

  /// The extrapolated position at [nowMs] on this device's clock.
  int positionAt(int nowMs) => PlaybackPosition.at(
    nowMs: nowMs,
    positionMs: player.positionMs.toInt(),
    positionAtMs: positionAtMs,
    playing: isPlaying,
    rate: player.playbackRate,
    durationMs: durationMs,
  );

  RemotePlayer copyWith({
    MediaPlayer? player,
    int? positionAtMs,
    bool? isConnected,
  }) => RemotePlayer(
    deviceId: deviceId,
    deviceName: deviceName,
    player: player ?? this.player,
    positionAtMs: positionAtMs ?? this.positionAtMs,
    lastActiveAtMs: lastActiveAtMs,
    artwork: artwork,
    isConnected: isConnected ?? this.isConnected,
  );
}
