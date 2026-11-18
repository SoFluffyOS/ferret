import 'dart:async';

import 'package:ferret_media/ferret_media.dart';
import 'package:flutter/widgets.dart';
import 'package:media/feature/feature.dart';
import 'package:media/models/models.dart';
import 'package:media/services/services.dart';
import 'package:media/view_models/media_notice.dart';
import 'package:media/view_models/media_platform.dart';
import 'package:protocol/media.dart';

/// What the media card and settings show, and what they can do.
class MediaViewModel extends ChangeNotifier {
  MediaViewModel(
    this._feature, {
    this.platform = .other,
    this.noticeLifetime = const Duration(seconds: 6),
  }) {
    _subscription = _feature.changes.listen((_) => _refresh());
    _refresh();
  }

  final MediaFeature _feature;
  final MediaPlatform platform;
  final Duration noticeLifetime;
  late final StreamSubscription<void> _subscription;

  List<RemotePlayer> _players = const [];
  RemotePlayer? _selected;
  PlayerPick? _pick;
  MediaNotice? _notice;
  Timer? _noticeTimer;
  bool _continuing = false;
  bool _askedAccess = false;
  bool _shareEnabled = false;
  bool _shareChosen = false;
  bool _showRemote = true;
  bool _pauseOnCall = true;
  MediaAccess? _access;

  List<RemotePlayer> get players => _players;

  RemotePlayer? get selected => _selected;

  MediaNotice? get notice => _notice;

  bool get isContinuing => _continuing;

  bool get shareEnabled => _shareEnabled;

  bool get showRemote => _showRemote;

  bool get pauseOnCall => _pauseOnCall;

  bool get canShare => _feature.canShare;

  MediaAccess? get access => _access;

  /// Whether other devices see what plays here right now: sharing is on and
  /// the platform lets Ferret see the players.
  bool get isSharing =>
      canShare &&
      _shareEnabled &&
      _access != .notGranted &&
      _access != .unsupported;

  /// The person turned sharing on, but Ferret may not see the players.
  bool get lostAccess => canShare && _shareChosen && _access == .notGranted;

  /// Whether this session already asked for access, so a refusal shows the
  /// way to System Settings instead of asking again.
  bool get askedAccess => _askedAccess;

  /// Whether the selected item can be opened here.
  bool get canContinue => _continueLink != null;

  /// Whether "Continue here" starts at the same position.
  bool get continueKeepsPosition => _continueLink?.keepsPosition ?? false;

  ContinueLink? get _continueLink => switch (_selected) {
    final player? => _feature.continueLinkFor(player),
    null => null,
  };

  /// Milliseconds since epoch, for the progress line.
  int now() => _feature.now;

  void select(PlayerKey key) {
    _pick = PlayerPick(key, _feature.now);
    _refresh();
  }

  Future<void> togglePlay() => _command(.MEDIA_ACTION_TOGGLE);

  Future<void> next() => _command(.MEDIA_ACTION_NEXT);

  Future<void> previous() => _command(.MEDIA_ACTION_PREVIOUS);

  Future<void> seekTo(int positionMs) =>
      _command(.MEDIA_ACTION_SEEK, positionMs: positionMs);

  Future<void> continueHere() async {
    final player = _selected;
    if (player == null || _continuing) {
      return;
    }

    _continuing = true;
    _clearNotice();
    notifyListeners();

    final outcome = await _feature.continueHere(player.key);

    _continuing = false;
    if (outcome case ContinueFailed(:final reason)) {
      _showNotice(
        ContinueNotice(
          reason,
          player.deviceName,
          appName: player.player.appName,
        ),
      );
    }

    notifyListeners();
  }

  Future<void> setShare(bool share) async {
    _shareEnabled = share;
    notifyListeners();
    await _feature.setShare(share);
    if (share) {
      _askedAccess = true;
    }

    _refresh();
  }

  Future<void> setShowRemote(bool show) async {
    _showRemote = show;
    notifyListeners();
    await _feature.setShowRemote(show);
    _refresh();
  }

  Future<void> setPauseOnCall(bool pause) async {
    _pauseOnCall = pause;
    notifyListeners();
    await _feature.setPauseOnCall(pause);
    _refresh();
  }

  Future<void> requestAccess() async {
    _askedAccess = true;
    await _feature.requestAccess();
    _refresh();
  }

  Future<void> openAccessSettings() => _feature.openAccessSettings();

  /// Gets access back the shortest way: macOS asks in place once, every
  /// other time the system settings are where it is allowed.
  Future<void> fixAccess() {
    if (platform == .macos && !_askedAccess) {
      return requestAccess();
    }

    return openAccessSettings();
  }

  Future<void> refreshAccess() async {
    await _feature.refreshAccess();
    _refresh();
  }

  void dismissNotice() {
    _clearNotice();
    notifyListeners();
  }

  Future<void> _command(MediaAction action, {int positionMs = 0}) async {
    final player = _selected;
    if (player == null) {
      return;
    }

    _clearNotice();
    final outcome = await _feature.command(
      player.key,
      action,
      positionMs: positionMs,
    );
    if (outcome != .ok) {
      _showNotice(CommandNotice(outcome, player.deviceName));
      notifyListeners();
    }
  }

  void _refresh() {
    _players = _feature.remotePlayers;
    _selected = PlayerSelector.select(_players, pick: _pick);
    _shareEnabled = _feature.shareEnabled;
    _shareChosen = _feature.shareChosen;
    _showRemote = _feature.showRemote;
    _pauseOnCall = _feature.pauseOnCall;
    _access = _feature.localAccess;
    notifyListeners();
  }

  void _showNotice(MediaNotice notice) {
    _notice = notice;
    _noticeTimer?.cancel();
    _noticeTimer = Timer(noticeLifetime, () {
      _notice = null;
      notifyListeners();
    });
  }

  void _clearNotice() {
    _noticeTimer?.cancel();
    _noticeTimer = null;
    _notice = null;
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    _noticeTimer?.cancel();
    super.dispose();
  }
}
