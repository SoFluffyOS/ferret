import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_media/ferret_media.dart';
import 'package:fixnum/fixnum.dart';
import 'package:media/feature/media_settings.dart';
import 'package:media/feature/remote_media_store.dart';
import 'package:media/models/models.dart';
import 'package:media/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/media.dart';
import 'package:protocol/protocol.dart';

/// Shares what this device plays with paired devices, shows what they play,
/// controls their players, and continues their media here at the same
/// position.
///
/// Local changes are sent when something changes, at most once per
/// [throttle]; positions are never sent on a timer, receivers extrapolate.
class MediaFeature extends Feature {
  MediaFeature({
    MediaBackend Function()? backend,
    LinkOpener linkOpener = const UrlLauncherLinkOpener(),
    this.shareByDefault = true,
    int Function()? clock,
    Duration throttle = const Duration(milliseconds: 500),
  }) : _backendFactory = backend,
       _linkOpener = linkOpener,
       _clock = clock ?? _wallClock {
    _throttle = ChangeThrottle(interval: throttle, onSend: _publish);
  }

  static const featureId = 'media';

  /// Flag in [FeatureSupport]: this device can share what it plays.
  static const shareFlag = 'share';
  static const _commandTimeout = Duration(seconds: 8);
  static const _continueTimeout = Duration(seconds: 10);

  /// Whether sharing starts on before the person chose, such as off on macOS
  /// where it needs the Automation permission.
  final bool shareByDefault;

  final MediaBackend Function()? _backendFactory;
  final LinkOpener _linkOpener;
  final int Function() _clock;
  final RemoteMediaStore _store = .new();
  final StreamController<void> _changes = .broadcast();
  final Map<String, PlayerInfo> _localPlayers = {};
  final Map<String, Uint8List> _localArtwork = {};
  final Map<String, Set<String>> _artworkSent = {};
  final List<StreamSubscription<Object?>> _backendSubscriptions = [];
  late final ChangeThrottle<List<MediaPlayer>> _throttle;

  MediaBackend? _backend;
  StreamSubscription<String>? _settingsSubscription;
  List<MediaPlayer> _published = const [];
  MediaAccess? _localAccess;
  bool _sharing = false;

  static int _wallClock() => DateTime.now().millisecondsSinceEpoch;

  @override
  String get id => featureId;

  @override
  List<String> get flags => [
    if (_backendFactory != null) shareFlag,
    'control',
  ];

  /// Fires whenever remote players, access or settings change.
  Stream<void> get changes => _changes.stream;

  /// Milliseconds since epoch on this device's clock.
  int get now => _clock();

  /// Whether this device can see its own players, or null before the first
  /// check or without a platform backend.
  MediaAccess? get localAccess => _localAccess;

  bool get canShare => _backendFactory != null;

  bool get shareEnabled =>
      host.settings.get<bool>(MediaSettings.share) ?? shareByDefault;

  /// Whether the person turned sharing on themselves, rather than it being
  /// on because that is where it starts.
  bool get shareChosen => host.settings.get<bool>(MediaSettings.share) == true;

  bool get showRemote =>
      host.settings.get<bool>(MediaSettings.showRemote) ?? true;

  bool get pauseOnCall =>
      host.settings.get<bool>(MediaSettings.pauseOnCall) ?? true;

  /// Players on connected devices, or none when showing them is off.
  List<RemotePlayer> get remotePlayers {
    if (!showRemote) {
      return const [];
    }

    return _store.connected;
  }

  RemotePlayer? player(PlayerKey key) => _store.find(key);

  /// The link "Continue here" would open, or null when this item can't be
  /// opened here.
  ContinueLink? continueLinkFor(RemotePlayer remote) => ContinueLinks.build(
    contentUri: remote.player.contentUri,
    appId: remote.player.appId,
    title: remote.player.title,
    artist: remote.player.artist,
    positionMs: remote.positionAt(now),
  );

  @override
  Future<void> onStart() async {
    _settingsSubscription = host.settings.changes
        .where((key) => key.startsWith('$featureId.'))
        .listen(_onSettingChanged);

    if (shareEnabled) {
      unawaited(_startSharing());
    }
  }

  @override
  Future<void> stop() async {
    await _settingsSubscription?.cancel();
    _settingsSubscription = null;
    await _stopSharing(announce: false);
  }

  @override
  void onSessionOpened(Session session) {
    _artworkSent.remove(session.remoteDeviceId);
    if (_sharing && _published.isNotEmpty && session.supports(featureId)) {
      unawaited(_sendState(session, _published));
    }
  }

  @override
  void onSessionClosed(Session session) {
    _artworkSent.remove(session.remoteDeviceId);
    _store.markDisconnected(session.remoteDeviceId);
    _emit();
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, MediaState.new) case final state?) {
      _onRemoteState(session, state);
      return null;
    }

    if (payloadOf(envelope, MediaStateRequest.new) != null) {
      return _stateFor(session, _sharedPlayers);
    }

    if (payloadOf(envelope, MediaCommand.new) case final command?) {
      return MediaCommandReply(result: await _runCommand(command));
    }

    if (payloadOf(envelope, MediaContinueRequest.new) case final request?) {
      return _handOver(request);
    }

    return null;
  }

  /// Turns sharing this device's media on or off. Turning it on asks for
  /// access when the platform needs it.
  Future<void> setShare(bool share) async {
    await host.settings.set(MediaSettings.share, share);
    if (!share) {
      await _stopSharing();
      return;
    }

    await _startSharing();
    if (_localAccess == .notGranted) {
      await requestAccess();
    }
  }

  Future<void> setPauseOnCall(bool pause) async {
    await host.settings.set(MediaSettings.pauseOnCall, pause);
    _emit();
  }

  /// Pauses every player on this device that is playing, such as when a
  /// call starts. Returns the ids of the players it paused, for
  /// [resumeLocalPlayback]. Never asks for access: without it, nothing is
  /// paused.
  Future<List<String>> pauseLocalPlayback() async {
    final players = await _readLocalPlayers();
    final backend = _backend;
    if (backend == null) {
      return const [];
    }

    final paused = <String>[];
    for (final player in players) {
      if (player.status != .playing || !_supports(player, .pause)) {
        continue;
      }

      if (await _localCommand(backend, player.id, .pause)) {
        paused.add(player.id);
      }
    }

    return paused;
  }

  /// Plays again the players [playerIds] that [pauseLocalPlayback] paused,
  /// unless they closed or someone already started them.
  Future<void> resumeLocalPlayback(List<String> playerIds) async {
    if (playerIds.isEmpty) {
      return;
    }

    final players = await _readLocalPlayers();
    final backend = _backend;
    if (backend == null) {
      return;
    }

    for (final player in players) {
      if (!playerIds.contains(player.id) || player.status == .playing) {
        continue;
      }

      await _localCommand(backend, player.id, .play);
    }
  }

  Future<void> setShowRemote(bool show) async {
    await host.settings.set(MediaSettings.showRemote, show);
    await _applyShowRemote();
  }

  /// Checks access again, such as when the app comes back from the system
  /// settings.
  Future<MediaAccess?> refreshAccess() async {
    final backend = _backend;
    if (backend == null) {
      return _localAccess;
    }

    await _updateAccess(await backend.access());
    return _localAccess;
  }

  /// Asks for access in place, or opens the page where people allow it.
  Future<MediaAccess?> requestAccess() async {
    final backend = _backend ?? _createBackend();
    if (backend == null) {
      return null;
    }

    await _updateAccess(await backend.requestAccess());
    return _localAccess;
  }

  Future<void> openAccessSettings() async =>
      (_backend ?? _createBackend())?.openAccessSettings();

  /// Sends [action] to a player on another device.
  Future<CommandOutcome> command(
    PlayerKey key,
    MediaAction action, {
    int positionMs = 0,
    double volume = 0,
  }) async {
    final session = host.sessionFor(key.deviceId);
    if (session == null) {
      return .unreachable;
    }

    final before = _store.find(key);
    if (before != null) {
      _showOptimistic(before, action, positionMs);
    }

    final outcome = await _send(
      session,
      MediaCommand(
        playerId: key.playerId,
        action: action,
        positionMs: Int64(positionMs),
        volume: volume,
      ),
    );
    if (outcome != .ok && before != null) {
      _store.replace(before);
      _emit();
    }

    return outcome;
  }

  /// Pauses a player on another device and opens what it played here, at
  /// the same position.
  Future<ContinueOutcome> continueHere(PlayerKey key) async {
    final remote = _store.find(key);
    if (remote == null || !remote.isConnected) {
      return const ContinueFailed(.playerGone);
    }

    final session = host.sessionFor(key.deviceId);
    if (session == null) {
      return const ContinueFailed(.unreachable);
    }

    if (continueLinkFor(remote) == null) {
      return const ContinueFailed(.noLink);
    }

    final MediaContinueReply reply;
    try {
      reply = await session.call(
        featureId,
        MediaContinueRequest(playerId: key.playerId, pauseSource: true),
        MediaContinueReply.new,
        timeout: _continueTimeout,
      );
    } on Object catch (error) {
      printWarning('Continue from ${key.deviceId} failed', error);
      return const ContinueFailed(.unreachable);
    }

    switch (reply.result) {
      case .MEDIA_COMMAND_RESULT_OK:
        break;
      case .MEDIA_COMMAND_RESULT_UNKNOWN_PLAYER:
        return const ContinueFailed(.playerGone);
      case .MEDIA_COMMAND_RESULT_NOT_SHARED:
        return const ContinueFailed(.notShared);
      default:
        return const ContinueFailed(.unreachable);
    }

    final item = reply.player;
    final positionMs = PlaybackPosition.at(
      nowMs: now,
      positionMs: item.positionMs.toInt(),
      positionAtMs: _store.toLocal(key.deviceId, item.positionAtMs.toInt()),
      playing: !reply.paused && item.status == .MEDIA_PLAYBACK_STATUS_PLAYING,
      rate: item.playbackRate,
      durationMs: item.durationMs.toInt(),
    );
    final link = ContinueLinks.build(
      contentUri: item.contentUri,
      appId: item.appId,
      title: item.title,
      artist: item.artist,
      positionMs: positionMs,
    );

    for (final uri in link?.candidates ?? const <Uri>[]) {
      if (await _linkOpener.open(uri)) {
        return ContinueOpened(uri);
      }
    }

    if (reply.paused) {
      unawaited(command(key, .MEDIA_ACTION_PLAY));
    }

    return const ContinueFailed(.openFailed);
  }

  Future<void> _startSharing() async {
    if (_sharing) {
      return;
    }

    final backend = _backend ?? _createBackend();
    if (backend == null) {
      return;
    }

    _sharing = true;
    try {
      await _updateAccess(await backend.access());
      if (_localAccess == .unsupported) {
        return;
      }

      _backendSubscriptions
        ..add(backend.players.listen(_onLocalPlayers))
        ..add(backend.accessChanges.listen(_onAccessChanged));
      await backend.startWatching();
      if (_localAccess == .granted && _sharing) {
        _onLocalPlayers(await backend.currentPlayers());
      }
    } on Object catch (error) {
      printWarning('Media sharing could not start', error);
    }
  }

  Future<void> _stopSharing({bool announce = true}) async {
    if (!_sharing) {
      return;
    }

    _sharing = false;
    _throttle.cancel();
    for (final subscription in _backendSubscriptions) {
      await subscription.cancel();
    }

    _backendSubscriptions.clear();
    try {
      await _backend?.stopWatching();
    } on Object catch (error) {
      printWarning('Media watching did not stop cleanly', error);
    }

    final hadPlayers = _published.isNotEmpty;
    _localPlayers.clear();
    _localArtwork.clear();
    _published = const [];
    if (announce && hadPlayers) {
      _publish(const []);
    }

    _emit();
  }

  MediaBackend? _createBackend() {
    final factory = _backendFactory;
    if (factory == null) {
      return null;
    }

    return _backend = factory();
  }

  Future<void> _updateAccess(MediaAccess access) async {
    final changed = access != _localAccess;
    _localAccess = access;
    if (!changed) {
      return;
    }

    _emit();
    if (access == .granted && _sharing) {
      await _backend?.startWatching();
    }
  }

  void _onAccessChanged(MediaAccess access) => unawaited(_updateAccess(access));

  void _onLocalPlayers(List<PlayerInfo> players) {
    if (!_sharing) {
      return;
    }

    _localPlayers
      ..clear()
      ..addAll({for (final player in players) player.id: player});

    final wire = [
      for (final player in players) MediaConversions.toWire(player),
    ];
    _localArtwork.clear();
    for (final player in players) {
      if (player.artwork case final artwork? when artwork.isNotEmpty) {
        _localArtwork[MediaConversions.artworkId(artwork)] = artwork;
      }
    }

    if (!MediaChangeFilter.isSignificant(_published, wire)) {
      return;
    }

    _published = wire;
    _throttle.push(wire);
  }

  List<MediaPlayer> get _sharedPlayers => switch (_sharing) {
    true => _published,
    false => const [],
  };

  void _publish(List<MediaPlayer> players) {
    for (final session in host.sessions) {
      if (session.supports(featureId)) {
        unawaited(_sendState(session, players));
      }
    }
  }

  Future<void> _sendState(Session session, List<MediaPlayer> players) async {
    try {
      await session.send(featureId, _stateFor(session, players));
    } on Object catch (error) {
      printDebug('Media state to ${session.remoteDeviceId} not sent: $error');
    }
  }

  /// [players] for [session], with each image the device hasn't had yet.
  MediaState _stateFor(Session session, List<MediaPlayer> players) {
    final sent = _artworkSent.putIfAbsent(session.remoteDeviceId, () => {});
    final outgoing = <MediaPlayer>[];
    for (final player in players) {
      final copy = player.deepCopy();
      final artwork = _localArtwork[player.artworkId];
      if (artwork != null && sent.add(player.artworkId)) {
        copy.artwork = artwork;
      }

      outgoing.add(copy);
    }

    return MediaState(players: outgoing, sentAtMs: Int64(now));
  }

  void _onRemoteState(Session session, MediaState state) {
    if (!showRemote) {
      return;
    }

    _store.apply(
      deviceId: session.remoteDeviceId,
      deviceName: session.remoteDevice?.name ?? session.remoteDeviceId,
      state: state,
      nowMs: now,
    );
    _emit();
  }

  Future<void> _applyShowRemote() async {
    if (!showRemote) {
      _store.clear();
      _emit();
      return;
    }

    for (final session in host.sessions) {
      if (!session.supports(featureId)) {
        continue;
      }

      try {
        final state = await session.call(
          featureId,
          MediaStateRequest(),
          MediaState.new,
          timeout: _commandTimeout,
        );
        _onRemoteState(session, state);
      } on Object catch (error) {
        printDebug('No media state from ${session.remoteDeviceId}: $error');
      }
    }
  }

  void _onSettingChanged(String key) {
    if (key == MediaSettings.share) {
      final run = switch (shareEnabled) {
        true => _startSharing(),
        false => _stopSharing(),
      };
      unawaited(run);
    }
  }

  Future<MediaCommandResult> _runCommand(MediaCommand command) async {
    final backend = _backend;
    if (!_sharing || backend == null) {
      return .MEDIA_COMMAND_RESULT_NOT_SHARED;
    }

    final info = _localPlayers[command.playerId];
    if (info == null) {
      return .MEDIA_COMMAND_RESULT_UNKNOWN_PLAYER;
    }

    final action = MediaConversions.actionFromWire(command.action);
    if (action == null || !_supports(info, action)) {
      return .MEDIA_COMMAND_RESULT_UNSUPPORTED;
    }

    try {
      final done = await backend.command(
        info.id,
        action,
        positionMs: command.positionMs.toInt(),
        volume: command.volume,
      );
      return switch (done) {
        true => .MEDIA_COMMAND_RESULT_OK,
        false => .MEDIA_COMMAND_RESULT_FAILED,
      };
    } on Object catch (error) {
      printWarning('Media command ${command.action} failed', error);
      return .MEDIA_COMMAND_RESULT_FAILED;
    }
  }

  Future<MediaContinueReply> _handOver(MediaContinueRequest request) async {
    final backend = _backend;
    if (!_sharing || backend == null) {
      return MediaContinueReply(result: .MEDIA_COMMAND_RESULT_NOT_SHARED);
    }

    final info = _localPlayers[request.playerId];
    if (info == null) {
      return MediaContinueReply(result: .MEDIA_COMMAND_RESULT_UNKNOWN_PLAYER);
    }

    final wasPlaying = info.status == .playing;
    var paused = false;
    if (request.pauseSource && wasPlaying) {
      try {
        paused = await backend.command(info.id, .pause);
      } on Object catch (error) {
        printWarning('Pausing for continue failed', error);
      }
    }

    final item = MediaConversions.toWire(info)
      ..positionMs = Int64(
        PlaybackPosition.at(
          nowMs: now,
          positionMs: info.positionMs,
          positionAtMs: info.positionAtMs,
          playing: wasPlaying,
          rate: info.playbackRate,
          durationMs: info.durationMs,
        ),
      )
      ..positionAtMs = Int64(now);
    if (paused) {
      item.status = .MEDIA_PLAYBACK_STATUS_PAUSED;
    }

    return MediaContinueReply(
      result: .MEDIA_COMMAND_RESULT_OK,
      player: item,
      paused: paused,
    );
  }

  Future<List<PlayerInfo>> _readLocalPlayers() async {
    final backend = _backend ?? _createBackend();
    if (backend == null) {
      return const [];
    }

    try {
      if (await backend.access() != .granted) {
        return const [];
      }

      return await backend.currentPlayers();
    } on Object catch (error) {
      printWarning('Reading the players on this device failed', error);
      return const [];
    }
  }

  Future<bool> _localCommand(
    MediaBackend backend,
    String playerId,
    PlayerAction action,
  ) async {
    try {
      return await backend.command(playerId, action);
    } on Object catch (error) {
      printWarning('Media $action on this device failed', error);
      return false;
    }
  }

  static bool _supports(PlayerInfo info, PlayerAction action) {
    final actions = info.actions;
    if (actions.isEmpty) {
      return true;
    }

    return switch (action) {
      .play || .pause || .toggle =>
        actions.contains(action) ||
            actions.contains(PlayerAction.toggle) ||
            actions.contains(PlayerAction.play) ||
            actions.contains(PlayerAction.pause),
      _ => actions.contains(action),
    };
  }

  Future<CommandOutcome> _send(Session session, MediaCommand command) async {
    try {
      final reply = await session.call(
        featureId,
        command,
        MediaCommandReply.new,
        timeout: _commandTimeout,
      );
      return switch (reply.result) {
        .MEDIA_COMMAND_RESULT_OK => .ok,
        .MEDIA_COMMAND_RESULT_UNKNOWN_PLAYER => .unknownPlayer,
        .MEDIA_COMMAND_RESULT_NOT_SHARED => .notShared,
        .MEDIA_COMMAND_RESULT_UNSUPPORTED => .unsupported,
        _ => .failed,
      };
    } on Object catch (error) {
      printWarning('Media command to ${session.remoteDeviceId} failed', error);
      return .unreachable;
    }
  }

  /// Shows the expected result of [action] right away; the device's next
  /// state confirms or corrects it.
  void _showOptimistic(RemotePlayer before, MediaAction action, int seekMs) {
    final nowMs = now;
    final position = before.positionAt(nowMs);
    final status = switch (action) {
      .MEDIA_ACTION_PLAY => MediaPlaybackStatus.MEDIA_PLAYBACK_STATUS_PLAYING,
      .MEDIA_ACTION_PAUSE => MediaPlaybackStatus.MEDIA_PLAYBACK_STATUS_PAUSED,
      .MEDIA_ACTION_TOGGLE => switch (before.isPlaying) {
        true => MediaPlaybackStatus.MEDIA_PLAYBACK_STATUS_PAUSED,
        false => MediaPlaybackStatus.MEDIA_PLAYBACK_STATUS_PLAYING,
      },
      _ => before.player.status,
    };
    final newPosition = switch (action) {
      .MEDIA_ACTION_SEEK => seekMs,
      _ => position,
    };
    if (status == before.player.status && newPosition == position) {
      return;
    }

    final updated = before.player.deepCopy()
      ..status = status
      ..positionMs = Int64(newPosition);
    _store.replace(before.copyWith(player: updated, positionAtMs: nowMs));
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
