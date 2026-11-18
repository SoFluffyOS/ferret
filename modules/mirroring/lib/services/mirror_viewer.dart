import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/foundation.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/feed_player.dart';
import 'package:mirroring/services/mirror_routes.dart';
import 'package:mirroring/services/viewer_stats_sink.dart';

/// The computer's side of screen mirroring: picks the way to a device,
/// opens a feed through it, follows it from the question on the other
/// side to the last picture, picks it up again after a dropped
/// connection, and keeps the numbers behind the quality mark. It only
/// knows feeds, never how they travel. One screen at a time.
class MirrorViewer {
  MirrorViewer({
    required MirrorRoutes routes,
    required MirrorDecoder Function() createDecoder,
    required List<MirrorCodec> codecs,
    required MirroringSettings settings,
    DateTime Function()? clock,
    this.consentMargin = const Duration(seconds: 5),
    this.firstPictureTimeout = const Duration(seconds: 10),
    this.statsInterval = const Duration(seconds: 1),
    this.maxDecoding = 12,
    this.reconnectGrace = const Duration(seconds: 20),
  }) : _routes = routes,
       _createDecoder = createDecoder,
       _codecs = codecs,
       _settings = settings,
       _clock = clock ?? DateTime.now;

  /// Added to the other side's own consent timeout before giving up on it.
  final Duration consentMargin;

  /// How long a first picture may take once the feed is open, and again
  /// after the owner's yes.
  final Duration firstPictureTimeout;

  final Duration statsInterval;

  /// Frames handed to the decoder and not shown yet at which new ones are
  /// dropped, up to the next keyframe.
  final int maxDecoding;

  /// How long the last picture stays after the connection dropped. The
  /// phone keeps its capture as long, so coming back in time needs no new
  /// prompt.
  final Duration reconnectGrace;

  /// How long a phone turns the same computer away after its owner said
  /// no, so "Ask again" waits as long.
  static const denyCooldown = Duration(seconds: 30);

  final MirrorRoutes _routes;
  final MirrorDecoder Function() _createDecoder;
  final List<MirrorCodec> _codecs;
  final MirroringSettings _settings;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final StreamController<void> _statsChanges = .broadcast();
  final ValueNotifier<MirrorPicture?> _picture = .new(null);
  final Map<String, ViewEnd> _lastEnds = {};

  ViewSession? _current;
  MirrorRecord? _lastRecord;
  MirrorFeed? _feed;
  StreamSubscription<FeedEvent>? _feedEvents;
  FeedPlayer? _player;
  StreamSubscription<void>? _reachable;
  Timer? _waitTimer;
  Timer? _statsTimer;
  Timer? _graceTimer;
  int _attempt = 0;

  /// The feed came through a route this computer can open again, not
  /// from a device that started it itself.
  bool _reopenable = false;
  bool _resuming = false;

  /// The device being asked or shown, or the last attempt and how it ended.
  ViewSession? get current => _current;

  /// The most recent time a screen was shown here since the app started,
  /// until dismissed.
  MirrorRecord? get lastRecord => _lastRecord;

  /// The picture to draw, or null before the first frame.
  ValueListenable<MirrorPicture?> get picture => _picture;

  /// Mouse, keyboard and buttons on the device being shown, when its route
  /// has them. Null means view only.
  MirrorControl? get control {
    final current = _current;
    if (current == null || !current.isMirroring) {
      return null;
    }

    return _feed?.control;
  }

  /// A device that started by itself is asked or shown right now.
  bool get isShowingIncoming => (_current?.isLive ?? false) && !_reopenable;

  /// How the last attempt with [deviceId] ended, for its health. Null when
  /// it never was asked, or shows its screen right now.
  ViewEnd? lastEndFor(String deviceId) => _lastEnds[deviceId];

  /// Fires when the session's phase, config or screen state changes.
  Stream<void> get changes => _changes.stream;

  /// Fires about every second while pictures show, with new numbers.
  Stream<void> get statsChanges => _statsChanges.stream;

  /// Shows the paired device [deviceId] the best way there is right now:
  /// Ferret, where its owner is asked, else the cable. [preferControl]
  /// takes the cable when it is there, to click and type.
  Future<void> show(String deviceId, {bool preferControl = false}) =>
      startTarget(
        _routes.bestTargetFor(deviceId, preferControl: preferControl),
      );

  /// Shows [target] through its route. A live attempt with the same device
  /// the same way is kept; anything else is stopped first.
  Future<void> startTarget(MirrorTarget target) async {
    final current = _current;
    if (current != null && current.isLive) {
      if (current.target == target) {
        return;
      }

      await stop();
    }

    await _open(target);
  }

  /// Shows a feed the other device started itself, in place of anything
  /// shown now.
  Future<void> showIncoming(MirrorFeed feed) async {
    await stop();

    final attempt = ++_attempt;
    _reopenable = false;
    _set(ViewSession(target: feed.target, phase: .requesting));
    _attach(feed, attempt);
  }

  /// Opens the picture again with the settings as they are now, keeping
  /// the last one on screen meanwhile. Only for a way that doesn't ask
  /// the device's owner: over Ferret a change waits for the next time.
  Future<void> restart() async {
    final current = _current;
    final feed = _feed;
    final asks = current?.target.routeId == _routes.ferret.id;
    if (current == null ||
        feed == null ||
        !current.isMirroring ||
        !_reopenable ||
        asks) {
      return;
    }

    _detach();
    await _stopFeed(feed);
    if (!identical(_current, current)) {
      return;
    }

    _set(current.copyWith(phase: .starting));
    await _reopen(current.target);
  }

  /// Stop or Back on this computer.
  Future<void> stop() async {
    final current = _current;
    if (current == null || !current.isLive) {
      return;
    }

    await _finish(.stoppedHere);
  }

  /// Forgets an attempt that is over, so its message goes away.
  void dismiss() {
    final current = _current;
    if (current == null || current.isLive) {
      return;
    }

    _current = null;
    _emit();
  }

  void dismissRecord() {
    _lastRecord = null;
    _emit();
  }

  Future<void> clearHistory() async {
    await _settings.clearHistory();
    _lastRecord = null;
    _emit();
  }

  Future<void> dispose() async {
    await stop();
    _waitTimer?.cancel();
    _statsTimer?.cancel();
    _stopLooking();
    await _closePlayer();
    _picture.dispose();
    await _changes.close();
    await _statsChanges.close();
  }

  Future<void> _open(MirrorTarget target, {bool viaFallback = false}) async {
    final attempt = ++_attempt;
    final route = _routes.routeFor(target);
    _reopenable = true;
    if (route == null) {
      _set(
        ViewSession(
          target: target,
          phase: .ended,
          end: .notConnected,
          endedAt: _clock(),
        ),
      );
      return;
    }

    _set(
      ViewSession(
        target: target,
        phase: .requesting,
        viaFallback: viaFallback,
      ),
    );
    final status = await _routes.statusOf(route);
    if (!_isAsking(attempt)) {
      return;
    }

    if (status case RouteNeedsSetup(:final step, :final detail)) {
      _set(
        ViewSession(
          target: target,
          phase: .ended,
          end: .needsSetup,
          setup: step,
          setupDetail: detail,
          endedAt: _clock(),
        ),
      );
      return;
    }

    if (status is RouteUnsupported) {
      await _finish(.unsupported);
      return;
    }

    final MirrorFeed feed;
    try {
      feed = await route.open(target, _settings.quality.options(_codecs));
    } on Object catch (error) {
      printWarning('Opening a screen through ${route.id} failed', error);
      await _endAttempt(attempt, .failed);
      return;
    }

    if (!_isAsking(attempt)) {
      await _stopFeed(feed);
      return;
    }

    _attach(feed, attempt);

    // A feed that already knows its first answer hands it over in the next
    // microtask: whoever awaits this sees where the attempt stands.
    await Future<void>.microtask(() {});
  }

  /// Opens [target] again for the session that is already on screen: after
  /// a dropped connection, or to apply new settings.
  Future<void> _reopen(MirrorTarget target) async {
    final attempt = ++_attempt;
    final route = _routes.routeFor(target);
    if (route == null) {
      await _finish(.lostConnection);
      return;
    }

    final MirrorFeed feed;
    try {
      feed = await route.open(target, _settings.quality.options(_codecs));
    } on Object catch (error) {
      printWarning('Opening a screen through ${route.id} failed', error);
      await _endAttempt(attempt, .lostConnection);
      return;
    }

    final current = _current;
    if (attempt != _attempt || current == null || !current.isLive) {
      await _stopFeed(feed);
      return;
    }

    _stopLooking();
    _attach(feed, attempt);
  }

  bool _isAsking(int attempt) =>
      attempt == _attempt && _current?.phase == .requesting;

  void _attach(MirrorFeed feed, int attempt) {
    _feed = feed;
    _waitTimer = Timer(
      firstPictureTimeout,
      () => unawaited(_endAttempt(attempt, .noAnswer)),
    );
    _feedEvents = feed.events.listen(
      (event) => _onEvent(feed, event),
      onError: (Object error) {
        printWarning('A mirrored screen stopped arriving', error);
        _onEvent(feed, const FeedEnded(.failed));
      },
    );
  }

  void _onEvent(MirrorFeed feed, FeedEvent event) {
    if (!identical(feed, _feed)) {
      return;
    }

    switch (event) {
      case FeedWaiting(:final timeout):
        _onWaiting(timeout);
      case FeedAccepted():
        _begin();
      case FeedConfigured(:final config):
        _begin();
        unawaited(_configure(config));
      case FeedFrame(:final frame, :final lost):
        _player?.add(frame, lost: lost);
      case FeedSourceState(:final screenOff):
        _onSourceState(screenOff);
      case FeedStats():
        _onStats(event);
      case FeedEnded(:final reason):
        unawaited(_finish(.ofFeed(reason)));
    }
  }

  void _onWaiting(Duration timeout) {
    // No time to answer means nobody is asked: the phone kept its capture
    // and says yes by itself.
    if (timeout == Duration.zero) {
      return;
    }

    final current = _current;
    final asked =
        current?.phase == .requesting || current?.phase == .reconnecting;
    if (current == null || !asked) {
      return;
    }

    final attempt = _attempt;
    _waitTimer?.cancel();
    _waitTimer = Timer(
      timeout + consentMargin,
      () => unawaited(_endAttempt(attempt, .timedOut)),
    );
    unawaited(_closePlayer());
    _set(
      current.copyWith(
        phase: .waitingForPhone,
        waitingUntil: _clock().add(timeout),
        lost: false,
      ),
    );
  }

  /// The other side said yes, or never had to: pictures are on their way.
  void _begin() {
    final current = _current;
    if (current == null || !current.isLive || current.isMirroring) {
      return;
    }

    final attempt = _attempt;
    _waitTimer?.cancel();
    _waitTimer = Timer(
      firstPictureTimeout,
      () => unawaited(_endAttempt(attempt, .noAnswer)),
    );
    if (_player == null) {
      _openPlayer();
    }

    _lastEnds.remove(current.deviceId);
    _statsTimer ??= .periodic(statsInterval, (_) => _onStatsTick());
    _set(
      current.copyWith(
        phase: .starting,
        startedAt: current.startedAt ?? _clock(),
        lost: false,
      ),
    );
  }

  Future<void> _configure(MirrorStreamConfig config) async {
    final player = _player;
    if (player == null) {
      return;
    }

    final result = await player.configure(config);
    if (!identical(_player, player) || result == .superseded) {
      return;
    }

    if (result == .failed) {
      await _finish(.decoderFailed);
      return;
    }

    _set(_current?.copyWith(config: config));
  }

  void _onSourceState(bool screenOff) {
    final current = _current;
    if (current == null || !current.isMirroring) {
      return;
    }

    _set(current.copyWith(screenOff: screenOff));
  }

  /// The other side's numbers: the round trip and its bitrate.
  void _onStats(FeedStats stats) {
    final current = _current;
    if (current == null || !current.isMirroring) {
      return;
    }

    final latencyMs = switch (stats.roundTrip) {
      final roundTrip? =>
        roundTrip.inMilliseconds ~/ 2 + (_player?.decodeMs ?? 0),
      null => current.stats.latencyMs,
    };
    _current = current.copyWith(
      stats: ViewStats(
        fps: current.stats.fps,
        latencyMs: latencyMs,
        bitrateKbps: stats.bitrateKbps,
        droppedFrames: current.stats.droppedFrames + stats.droppedFrames,
      ),
    );
    _emitStats();
  }

  void _openPlayer() {
    final player = FeedPlayer(
      decoder: _createDecoder(),
      clock: _clock,
      maxDecoding: maxDecoding,
      onShown: _onShown,
      onKeyframeNeeded: () => unawaited(_requestKeyframe(_feed)),
    );
    _player = player;
    player.picture.addListener(_onPicture);
  }

  Future<void> _closePlayer() async {
    final player = _player;
    _player = null;
    if (player == null) {
      return;
    }

    player.picture.removeListener(_onPicture);
    _picture.value = null;
    await player.close();
  }

  void _onPicture() => _picture.value = _player?.picture.value;

  void _onShown() {
    final current = _current;
    if (current == null || current.phase != .starting) {
      return;
    }

    _waitTimer?.cancel();
    _waitTimer = null;
    _set(current.copyWith(phase: .streaming));
  }

  Future<void> _requestKeyframe(MirrorFeed? feed) async {
    if (feed == null || !identical(feed, _feed)) {
      return;
    }

    try {
      await feed.requestKeyframe();
    } on Object catch (error) {
      printWarning('Asking for a keyframe failed', error);
    }
  }

  void _onStatsTick() {
    final current = _current;
    final player = _player;
    if (current == null || !current.isMirroring || player == null) {
      return;
    }

    final window = player.takeWindow();
    _current = current.copyWith(
      stats: ViewStats(
        fps: window.shown,
        latencyMs: current.stats.latencyMs,
        bitrateKbps: current.stats.bitrateKbps,
        droppedFrames: window.dropped,
      ),
    );
    _emitStats();
    if (_feed case final ViewerStatsSink sink) {
      sink.reportStats(
        sentAt: _clock(),
        fps: window.shown,
        droppedFrames: window.dropped,
      );
    }
  }

  Future<void> _endAttempt(int attempt, ViewEnd end) async {
    if (attempt != _attempt) {
      return;
    }

    await _finish(end);
  }

  /// Ends the current attempt, unless there is a way to go on: over the
  /// cable when Ferret never reached the phone, or by waiting for a
  /// device whose connection dropped. Otherwise the picture goes away, the
  /// feed is told to stop (one that ended by itself has nothing left to
  /// do), and a session that showed anything is recorded.
  Future<void> _finish(ViewEnd end) async {
    final current = _current;
    if (current == null || !current.isLive) {
      return;
    }

    if (_fallbackFor(current, end) case final cable?) {
      final feed = _detach();
      if (feed != null) {
        await _stopFeed(feed);
      }

      await _open(cable, viaFallback: true);
      return;
    }

    if (end == .lostConnection && current.isMirroring && _reopenable) {
      _reconnect(current);
      return;
    }

    final feed = _detach();
    _stopLooking();
    _statsTimer?.cancel();
    _statsTimer = null;
    _current = current.copyWith(phase: .ended, end: end, endedAt: _clock());
    _lastEnds[current.deviceId] = end;
    final record = _recordOf(current, end);
    if (record != null) {
      _lastRecord = record;
    }

    _emit();
    if (feed != null) {
      await _stopFeed(feed);
    }

    await _closePlayer();
    if (record != null) {
      await _settings.addRecord(record);
    }

    if (!_reopenable) {
      await _routes.refreshReceivers();
    }

    _emit();
  }

  /// The cable's way to the phone of [session], when Ferret couldn't
  /// reach or ask it. Never after its owner answered, and never twice.
  MirrorTarget? _fallbackFor(ViewSession session, ViewEnd end) {
    final overFerret = session.target.routeId == _routes.ferret.id;
    if (!overFerret || session.startedAt != null || !end.mayFallBack) {
      return null;
    }

    final cable = _routes.cableTargetFor(session.deviceId);
    if (cable == null || _routes.routeFor(cable) == null) {
      return null;
    }

    return cable;
  }

  /// The connection dropped while pictures showed: the last one stays,
  /// and the device is asked again once, as soon as it is back.
  void _reconnect(ViewSession session) {
    _detach();
    _resuming = false;
    _current = session.copyWith(phase: .reconnecting, screenOff: false);
    _emit();
    _graceTimer = Timer(reconnectGrace, _onGraceOver);
    _reachable = _routes.changes.listen((_) => _resume());
    _resume();
  }

  void _onGraceOver() {
    final current = _current;
    if (current == null || current.phase != .reconnecting) {
      return;
    }

    unawaited(_closePlayer());
    _set(current.copyWith(lost: true));
  }

  void _resume() {
    final current = _current;
    final waits = current != null && current.phase == .reconnecting;
    if (current == null ||
        !waits ||
        _resuming ||
        !_routes.isReachable(current.target)) {
      return;
    }

    _resuming = true;
    unawaited(_reopen(current.target));
  }

  void _stopLooking() {
    _graceTimer?.cancel();
    _graceTimer = null;
    unawaited(_reachable?.cancel());
    _reachable = null;
  }

  /// Lets go of the feed without telling it anything, and hands it back.
  MirrorFeed? _detach() {
    final feed = _feed;
    unawaited(_feedEvents?.cancel());
    _feed = null;
    _feedEvents = null;
    _waitTimer?.cancel();
    _waitTimer = null;
    return feed;
  }

  Future<void> _stopFeed(MirrorFeed feed) async {
    try {
      await feed.stop();
    } on Object catch (error) {
      printWarning('Stopping a mirrored screen failed', error);
    }
  }

  MirrorRecord? _recordOf(ViewSession session, ViewEnd end) {
    final startedAt = session.startedAt;
    if (startedAt == null) {
      return null;
    }

    return MirrorRecord(
      deviceId: session.deviceId,
      deviceName: session.deviceName,
      role: .viewed,
      startedAt: startedAt,
      endedAt: _clock(),
      end: switch (end) {
        .stoppedHere => .viewerDone,
        .stoppedOnPhone => .stoppedOnPhone,
        .systemEnded => .systemEnded,
        .turnedOff => .turnedOff,
        .lostConnection => .lostConnection,
        _ => .failed,
      },
    );
  }

  void _set(ViewSession? session) {
    if (session == null) {
      return;
    }

    _current = session;
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  void _emitStats() {
    if (!_statsChanges.isClosed) {
      _statsChanges.add(null);
    }
  }
}
