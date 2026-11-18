import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_media/ferret_media.dart';

/// A media backend driven by the test.
class FakeMediaBackend implements MediaBackend {
  FakeMediaBackend({this.accessState = MediaAccess.granted});

  MediaAccess accessState;
  MediaAccess? accessAfterRequest;
  bool commandSucceeds = true;
  bool watching = false;
  int accessRequests = 0;
  int settingsOpened = 0;
  List<PlayerInfo> current = [];
  final List<({String playerId, PlayerAction action, int positionMs})>
  commands = [];
  final StreamController<List<PlayerInfo>> _players = .broadcast();
  final StreamController<MediaAccess> _access = .broadcast();

  /// Reports [players] like a platform callback would.
  void emit(List<PlayerInfo> players) {
    current = players;
    _players.add(players);
  }

  @override
  Stream<List<PlayerInfo>> get players => _players.stream;

  @override
  Stream<MediaAccess> get accessChanges => _access.stream;

  @override
  Future<MediaAccess> access() async => accessState;

  @override
  Future<MediaAccess> requestAccess() async {
    accessRequests++;
    if (accessAfterRequest case final after?) {
      accessState = after;
    }

    return accessState;
  }

  @override
  Future<void> openAccessSettings() async => settingsOpened++;

  @override
  Future<void> startWatching() async => watching = true;

  @override
  Future<void> stopWatching() async => watching = false;

  @override
  Future<List<PlayerInfo>> currentPlayers() async => current;

  @override
  Future<bool> command(
    String playerId,
    PlayerAction action, {
    int positionMs = 0,
    double volume = 0,
  }) async {
    commands.add((playerId: playerId, action: action, positionMs: positionMs));
    return commandSucceeds;
  }
}

/// A player as a platform backend reports it.
PlayerInfo playerInfo({
  String id = 'spotify',
  String appId = 'com.spotify.music',
  String appName = 'Spotify',
  String title = 'Teardrop',
  String artist = 'Massive Attack',
  PlayerStatus status = PlayerStatus.playing,
  int positionMs = 60000,
  int positionAtMs = 1000000,
  int durationMs = 330000,
  String? contentUri,
  Uint8List? artwork,
  int lastActiveAtMs = 900000,
  List<PlayerAction> actions = const [
    PlayerAction.play,
    PlayerAction.pause,
    PlayerAction.toggle,
    PlayerAction.next,
    PlayerAction.previous,
    PlayerAction.seek,
  ],
}) => PlayerInfo(
  id: id,
  appId: appId,
  appName: appName,
  title: title,
  artist: artist,
  album: 'Mezzanine',
  artwork: artwork,
  durationMs: durationMs,
  positionMs: positionMs,
  positionAtMs: positionAtMs,
  status: status,
  playbackRate: 1,
  contentUri: contentUri,
  lastActiveAtMs: lastActiveAtMs,
  actions: actions,
  volume: -1,
);
