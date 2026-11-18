import 'dart:async';

import 'package:ferret_media/src/media_backend.dart';
import 'package:ferret_media/src/messages.g.dart';

/// The native backends on Android, iOS, macOS and Windows.
class PigeonMediaBackend implements MediaBackend, MediaFlutterApi {
  PigeonMediaBackend({MediaHostApi? api}) : _api = api ?? MediaHostApi() {
    MediaFlutterApi.setUp(this);
  }

  final MediaHostApi _api;
  final StreamController<List<PlayerInfo>> _players = .broadcast();
  final StreamController<MediaAccess> _access = .broadcast();

  @override
  Stream<List<PlayerInfo>> get players => _players.stream;

  @override
  Stream<MediaAccess> get accessChanges => _access.stream;

  @override
  Future<MediaAccess> access() => _api.access();

  @override
  Future<MediaAccess> requestAccess() => _api.requestAccess();

  @override
  Future<void> openAccessSettings() => _api.openAccessSettings();

  @override
  Future<void> startWatching() => _api.startWatching();

  @override
  Future<void> stopWatching() => _api.stopWatching();

  @override
  Future<List<PlayerInfo>> currentPlayers() => _api.players();

  @override
  Future<bool> command(
    String playerId,
    PlayerAction action, {
    int positionMs = 0,
    double volume = 0,
  }) => _api.command(playerId, action, positionMs, volume);

  @override
  void onPlayersChanged(List<PlayerInfo> players) => _players.add(players);

  @override
  void onAccessChanged(MediaAccess access) => _access.add(access);
}
