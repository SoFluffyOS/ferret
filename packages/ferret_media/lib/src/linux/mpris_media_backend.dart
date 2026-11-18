import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dbus/dbus.dart';
import 'package:ferret_media/src/artwork_shrinker.dart';
import 'package:ferret_media/src/linux/mpris_metadata.dart';
import 'package:ferret_media/src/media_backend.dart';
import 'package:ferret_media/src/messages.g.dart';

/// Media players on Linux through MPRIS on the session D-Bus. No permission
/// is needed.
class MprisMediaBackend implements MediaBackend {
  MprisMediaBackend({DBusClient Function()? connect})
    : _connect = connect ?? DBusClient.session;

  static const _playerInterface = 'org.mpris.MediaPlayer2.Player';
  static const _rootInterface = 'org.mpris.MediaPlayer2';
  static final _path = DBusObjectPath('/org/mpris/MediaPlayer2');
  static const _emitDelay = Duration(milliseconds: 200);

  final DBusClient Function() _connect;
  final StreamController<List<PlayerInfo>> _players = .broadcast();
  final Map<String, _TrackedPlayer> _tracked = {};

  DBusClient? _client;
  StreamSubscription<DBusNameOwnerChangedEvent>? _namesSubscription;
  Timer? _emitTimer;
  bool _watching = false;

  @override
  Stream<List<PlayerInfo>> get players => _players.stream;

  @override
  Stream<MediaAccess> get accessChanges => const Stream.empty();

  @override
  Future<MediaAccess> access() async => .granted;

  @override
  Future<MediaAccess> requestAccess() async => .granted;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> startWatching() async {
    if (_watching) {
      return;
    }

    _watching = true;
    final client = _ensureClient();
    _namesSubscription = client.nameOwnerChanged.listen(_onNameOwnerChanged);

    final names = await client.listNames();
    for (final name in names) {
      if (name.startsWith(MprisMetadata.busPrefix)) {
        await _track(name);
      }
    }

    _scheduleEmit();
  }

  @override
  Future<void> stopWatching() async {
    if (!_watching) {
      return;
    }

    _watching = false;
    _emitTimer?.cancel();
    await _namesSubscription?.cancel();
    _namesSubscription = null;
    for (final tracked in _tracked.values) {
      await tracked.dispose();
    }

    _tracked.clear();
    await _client?.close();
    _client = null;
  }

  @override
  Future<List<PlayerInfo>> currentPlayers() async {
    if (!_watching) {
      return const [];
    }

    return _snapshot();
  }

  @override
  Future<bool> command(
    String playerId,
    PlayerAction action, {
    int positionMs = 0,
    double volume = 0,
  }) async {
    final tracked = _tracked[playerId];
    if (tracked == null) {
      return false;
    }

    try {
      await _run(tracked, action, positionMs: positionMs, volume: volume);
      return true;
    } on DBusMethodResponseException {
      return false;
    }
  }

  Future<void> _run(
    _TrackedPlayer tracked,
    PlayerAction action, {
    required int positionMs,
    required double volume,
  }) async {
    final object = tracked.object;
    switch (action) {
      case .play:
        await object.callMethod(_playerInterface, 'Play', const []);
      case .pause:
        await object.callMethod(_playerInterface, 'Pause', const []);
      case .toggle:
        await object.callMethod(_playerInterface, 'PlayPause', const []);
      case .next:
        await object.callMethod(_playerInterface, 'Next', const []);
      case .previous:
        await object.callMethod(_playerInterface, 'Previous', const []);
      case .seek:
        await _seek(tracked, positionMs);
      case .setVolume:
        await object.setProperty(
          _playerInterface,
          'Volume',
          DBusDouble(volume.clamp(0, 1).toDouble()),
        );
    }
  }

  Future<void> _seek(_TrackedPlayer tracked, int positionMs) async {
    final properties = await tracked.object.getAllProperties(_playerInterface);
    final metadata = MprisMetadata(properties);
    final targetMicros = positionMs * 1000;
    if (metadata.trackId case final trackId?) {
      await tracked.object.callMethod(_playerInterface, 'SetPosition', [
        DBusObjectPath(trackId),
        DBusInt64(targetMicros),
      ]);
      return;
    }

    final offset = targetMicros - metadata.positionMs * 1000;
    await tracked.object.callMethod(_playerInterface, 'Seek', [
      DBusInt64(offset),
    ]);
  }

  DBusClient _ensureClient() => _client ??= _connect();

  Future<void> _onNameOwnerChanged(DBusNameOwnerChangedEvent event) async {
    if (!event.name.startsWith(MprisMetadata.busPrefix)) {
      return;
    }

    if (event.newOwner == null) {
      await _tracked.remove(event.name)?.dispose();
      _scheduleEmit();
      return;
    }

    await _track(event.name);
    _scheduleEmit();
  }

  Future<void> _track(String busName) async {
    if (_tracked.containsKey(busName)) {
      return;
    }

    final object = DBusRemoteObject(
      _ensureClient(),
      name: busName,
      path: _path,
    );
    final tracked = _TrackedPlayer(busName, object);
    _tracked[busName] = tracked;

    try {
      final root = await object.getAllProperties(_rootInterface);
      tracked
        ..appName = switch (root['Identity']) {
          final DBusString identity when identity.value.isNotEmpty =>
            identity.value,
          _ => busName.substring(MprisMetadata.busPrefix.length),
        }
        ..appId = switch (root['DesktopEntry']) {
          final DBusString entry when entry.value.isNotEmpty => entry.value,
          _ => busName.substring(MprisMetadata.busPrefix.length),
        };
    } on Object {
      tracked
        ..appName = busName.substring(MprisMetadata.busPrefix.length)
        ..appId = tracked.appName;
    }

    tracked.subscriptions
      ..add(
        object.propertiesChanged.listen((signal) {
          if (signal.propertiesInterface == _playerInterface) {
            _scheduleEmit();
          }
        }, onError: (Object _) {}),
      )
      ..add(
        DBusRemoteObjectSignalStream(
          object: object,
          interface: _playerInterface,
          name: 'Seeked',
        ).listen((_) => _scheduleEmit(), onError: (Object _) {}),
      );
  }

  void _scheduleEmit() {
    if (!_watching) {
      return;
    }

    _emitTimer?.cancel();
    _emitTimer = Timer(_emitDelay, () async {
      final players = await _snapshot();
      if (_watching) {
        _players.add(players);
      }
    });
  }

  Future<List<PlayerInfo>> _snapshot() async {
    final players = <PlayerInfo>[];
    for (final tracked in [..._tracked.values]) {
      if (await _read(tracked) case final player?) {
        players.add(player);
      }
    }

    return players;
  }

  Future<PlayerInfo?> _read(_TrackedPlayer tracked) async {
    final Map<String, DBusValue> properties;
    try {
      properties = await tracked.object.getAllProperties(_playerInterface);
    } on Object {
      return null;
    }

    final metadata = MprisMetadata(properties);
    final now = DateTime.now().millisecondsSinceEpoch;
    final playing = metadata.status == .playing;
    if (tracked.title != metadata.title || (playing && !tracked.wasPlaying)) {
      tracked.lastActiveAtMs = now;
    }

    tracked
      ..title = metadata.title
      ..wasPlaying = playing;

    final player = metadata.toPlayer(
      busName: tracked.busName,
      appName: tracked.appName,
      appId: tracked.appId,
      nowMs: now,
      lastActiveAtMs: tracked.lastActiveAtMs,
    );
    if (player == null) {
      return null;
    }

    player.artwork = await _artwork(tracked, metadata.artUrl);
    return player;
  }

  // Only local files: fetching a web artwork URL would be a network call to
  // a third party.
  Future<Uint8List?> _artwork(_TrackedPlayer tracked, String? artUrl) async {
    if (artUrl == tracked.artUrl) {
      return tracked.artwork;
    }

    tracked
      ..artUrl = artUrl
      ..artwork = null;
    if (artUrl == null || !artUrl.startsWith('file://')) {
      return null;
    }

    try {
      final file = File(Uri.parse(artUrl).toFilePath());
      tracked.artwork = await ArtworkShrinker.shrink(await file.readAsBytes());
    } on Object {
      tracked.artwork = null;
    }

    return tracked.artwork;
  }
}

class _TrackedPlayer {
  _TrackedPlayer(this.busName, this.object);

  final String busName;
  final DBusRemoteObject object;
  final List<StreamSubscription<Object?>> subscriptions = [];
  String appName = '';
  String appId = '';
  String title = '';
  bool wasPlaying = false;
  int lastActiveAtMs = 0;
  String? artUrl;
  Uint8List? artwork;

  Future<void> dispose() async {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }

    subscriptions.clear();
  }
}
