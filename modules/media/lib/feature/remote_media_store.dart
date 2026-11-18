import 'dart:typed_data';

import 'package:media/models/models.dart';
import 'package:protocol/media.dart';

/// The last known players of each device, with their times on this
/// device's clock and the artwork each device sent.
class RemoteMediaStore {
  static const _maxArtworkPerDevice = 32;

  final Map<String, _DeviceMedia> _devices = {};

  /// Every known player, including those of disconnected devices.
  List<RemotePlayer> get all => [
    for (final device in _devices.values) ...device.players,
  ];

  /// Players of connected devices.
  List<RemotePlayer> get connected => [
    for (final device in _devices.values)
      if (device.isConnected) ...device.players,
  ];

  /// Takes [state] from [deviceId], received at [nowMs] on this device.
  void apply({
    required String deviceId,
    required String deviceName,
    required MediaState state,
    required int nowMs,
  }) {
    final device = _devices.putIfAbsent(deviceId, _DeviceMedia.new)
      ..isConnected = true
      ..offsetMs = switch (state.sentAtMs.toInt()) {
        0 => 0,
        final sentAt => nowMs - sentAt,
      };

    for (final player in state.players) {
      if (player.artwork.isNotEmpty && player.artworkId.isNotEmpty) {
        device.remember(player.artworkId, Uint8List.fromList(player.artwork));
      }
    }

    device.players = [
      for (final player in state.players)
        RemotePlayer(
          deviceId: deviceId,
          deviceName: deviceName,
          player: player.deepCopy()..clearArtwork(),
          positionAtMs: device.toLocal(player.positionAtMs.toInt()),
          lastActiveAtMs: device.toLocal(player.lastActiveAtMs.toInt()),
          artwork: device.artwork[player.artworkId],
        ),
    ];
    device.trimArtwork(
      keep: {for (final player in state.players) player.artworkId},
      max: _maxArtworkPerDevice,
    );
  }

  RemotePlayer? find(PlayerKey key) {
    for (final player in _devices[key.deviceId]?.players ?? <RemotePlayer>[]) {
      if (player.player.playerId == key.playerId) {
        return player;
      }
    }

    return null;
  }

  /// Replaces one player, such as to show a pause before the device
  /// confirms it.
  void replace(RemotePlayer updated) {
    final device = _devices[updated.deviceId];
    if (device == null) {
      return;
    }

    device.players = [
      for (final player in device.players)
        switch (player.key == updated.key) {
          true => updated,
          false => player,
        },
    ];
  }

  /// Maps a time on [deviceId]'s clock onto this device's clock.
  int toLocal(String deviceId, int remoteMs) =>
      _devices[deviceId]?.toLocal(remoteMs) ?? remoteMs;

  void markDisconnected(String deviceId) {
    final device = _devices[deviceId];
    if (device == null) {
      return;
    }

    device
      ..isConnected = false
      ..players = [
        for (final player in device.players)
          player.copyWith(isConnected: false),
      ];
  }

  void clear() => _devices.clear();
}

class _DeviceMedia {
  bool isConnected = true;
  int offsetMs = 0;
  List<RemotePlayer> players = const [];
  final Map<String, Uint8List> artwork = {};

  int toLocal(int remoteMs) {
    if (remoteMs <= 0) {
      return 0;
    }

    return remoteMs + offsetMs;
  }

  void remember(String id, Uint8List bytes) {
    artwork
      ..remove(id)
      ..[id] = bytes;
  }

  void trimArtwork({required Set<String> keep, required int max}) {
    final removable = [
      for (final id in artwork.keys)
        if (!keep.contains(id)) id,
    ];
    var excess = artwork.length - max;
    for (final id in removable) {
      if (excess <= 0) {
        return;
      }

      artwork.remove(id);
      excess--;
    }
  }
}
