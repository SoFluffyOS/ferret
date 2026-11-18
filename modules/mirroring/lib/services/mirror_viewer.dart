import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/mirror_protocol.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';
import 'package:protocol/protocol.dart';

/// The computer's side of screen mirroring: asks a phone for its screen,
/// waits for its owner, decodes what arrives, and keeps the numbers for
/// the status line. One phone at a time.
class MirrorViewer {
  MirrorViewer({
    required FeatureHost host,
    required String featureId,
    required MirrorDecoder Function() createDecoder,
    required List<MirrorCodec> codecs,
    required MirroringSettings settings,
    DateTime Function()? clock,
    this.requestTimeout = const Duration(seconds: 10),
    this.consentMargin = const Duration(seconds: 5),
    this.firstPictureTimeout = const Duration(seconds: 10),
    this.statsInterval = const Duration(seconds: 1),
    this.maxDecoding = 12,
  }) : _host = host,
       _featureId = featureId,
       _createDecoder = createDecoder,
       _codecs = codecs,
       _settings = settings,
       _clock = clock ?? DateTime.now;

  /// How long the phone has to answer the request itself.
  final Duration requestTimeout;

  /// Added to the phone's own consent timeout before giving up on it.
  final Duration consentMargin;

  /// How long after the owner's yes a first picture may take.
  final Duration firstPictureTimeout;

  final Duration statsInterval;

  /// Frames handed to the decoder and not shown yet at which new ones are
  /// dropped, up to the next keyframe.
  final int maxDecoding;

  /// Frames kept while the decoder is being set up for a new config.
  static const _maxHeldFrames = 120;
  static const _keyframeRequestGap = Duration(milliseconds: 500);
  static const _strayNoticeGap = Duration(seconds: 1);

  final FeatureHost _host;
  final String _featureId;
  final MirrorDecoder Function() _createDecoder;
  final List<MirrorCodec> _codecs;
  final MirroringSettings _settings;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final StreamController<void> _statsChanges = .broadcast();
  final ValueNotifier<MirrorPicture?> _picture = .new(null);
  final List<StreamSubscription<Object?>> _decoderSubscriptions = [];
  final Map<int, DateTime> _decodingSince = {};
  final List<Frame> _held = [];
  final Map<String, DateTime> _strayNoticeAt = {};
  final Map<String, ViewEnd> _lastEnds = {};

  ViewSession? _current;
  MirrorRecord? _lastRecord;
  MirrorDecoder? _decoder;
  Timer? _waitTimer;
  Timer? _statsTimer;
  int? _configId;
  bool _configuring = false;
  bool _needsKeyframe = true;
  Int64? _lastSequence;
  DateTime? _keyframeAskedAt;
  int _shownInWindow = 0;
  int _droppedInWindow = 0;
  int _decodeMs = 0;
  int _attempt = 0;

  /// The phone being asked or shown, or the last attempt and how it ended.
  ViewSession? get current => _current;

  /// The most recent time a screen was shown here since the app started,
  /// until dismissed.
  MirrorRecord? get lastRecord => _lastRecord;

  /// The picture to draw, or null before the first frame.
  ValueListenable<MirrorPicture?> get picture => _picture;

  /// How the last attempt with [deviceId] ended, for its health. Null when
  /// it never was asked, or shows its screen right now.
  ViewEnd? lastEndFor(String deviceId) => _lastEnds[deviceId];

  /// Fires when the session's phase, config or screen state changes.
  Stream<void> get changes => _changes.stream;

  /// Fires about every second while pictures show, with new numbers.
  Stream<void> get statsChanges => _statsChanges.stream;

  /// Asks [deviceId] for its screen. A live attempt with the same device is
  /// kept; one with another device is stopped first.
  Future<void> start(String deviceId) async {
    final current = _current;
    if (current != null && current.isLive) {
      if (current.deviceId == deviceId) {
        return;
      }

      await stop();
    }

    final attempt = ++_attempt;
    final session = _host.sessionFor(deviceId);
    final name = _nameOf(deviceId, session);
    if (session == null) {
      _set(
        ViewSession(
          deviceId: deviceId,
          deviceName: name,
          phase: .ended,
          end: .notConnected,
        ),
      );
      return;
    }

    _set(ViewSession(deviceId: deviceId, deviceName: name, phase: .requesting));
    final Envelope reply;
    try {
      reply = await session.request(
        _featureId,
        StartRequest(
          version: MirrorProtocol.version,
          codecs: _codecs.map(MirrorProtocol.toProto),
          maxWidth: MirrorProtocol.maxLongSide,
          maxHeight: MirrorProtocol.maxLongSide,
          maxFps: MirrorProtocol.maxFps,
        ),
        timeout: requestTimeout,
      );
    } on SessionClosedException {
      await _endAttempt(attempt, .lostConnection);
      return;
    } on Object catch (error) {
      printWarning('Asking $deviceId for its screen failed', error);
      await _endAttempt(attempt, .noAnswer);
      return;
    }

    if (attempt != _attempt || _current?.phase != .requesting) {
      return;
    }

    if (payloadOf(reply, StartPending.new) case final pending?) {
      _waitTimer = Timer(
        Duration(seconds: pending.timeoutSeconds) + consentMargin,
        () => unawaited(_giveUp(attempt, .timedOut)),
      );
      _set(_current?.copyWith(phase: .waitingForPhone));
      return;
    }

    if (payloadOf(reply, StartDeny.new) case final deny?) {
      await _finish(_endOfDeny(deny.reason));
      return;
    }

    await _finish(.noAnswer);
  }

  /// Stop or Back on this computer.
  Future<void> stop() async {
    final current = _current;
    if (current == null || !current.isLive) {
      return;
    }

    await _finish(.stoppedHere, notify: .STOP_REASON_VIEWER_DONE);
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

  void onAccept(Session session, StartAccept accept) {
    final current = _current;
    if (current == null ||
        current.phase != .waitingForPhone ||
        current.deviceId != session.remoteDeviceId) {
      _answerStray(session);
      return;
    }

    final attempt = _attempt;
    _waitTimer?.cancel();
    _waitTimer = Timer(
      firstPictureTimeout,
      () => unawaited(_giveUp(attempt, .noAnswer)),
    );
    _resetStream();
    _openDecoder();
    _lastEnds.remove(current.deviceId);
    _statsTimer = .periodic(statsInterval, (_) => _onStatsTick());
    _set(current.copyWith(phase: .starting, startedAt: _clock()));
  }

  Future<void> onDeny(Session session, StartDeny deny) async {
    final current = _current;
    if (current == null ||
        current.phase != .waitingForPhone ||
        current.deviceId != session.remoteDeviceId) {
      return;
    }

    await _finish(_endOfDeny(deny.reason));
  }

  Future<void> onConfig(Session session, StreamConfig config) async {
    final current = _current;
    final decoder = _decoder;
    final codec = MirrorProtocol.fromProto(config.codec);
    if (!_isMirroring(session) || current == null || decoder == null) {
      return;
    }

    if (codec == null) {
      await _finish(.decoderFailed, notify: .STOP_REASON_VIEWER_DONE);
      return;
    }

    final streamConfig = MirrorStreamConfig(
      codec: codec,
      width: config.width,
      height: config.height,
      rotation: config.rotation,
      fps: config.fps,
      sps: Uint8List.fromList(config.sps),
      pps: Uint8List.fromList(config.pps),
    );
    _configId = config.configId;
    _configuring = true;
    _needsKeyframe = true;
    _held.clear();
    _decodingSince.clear();
    try {
      await decoder.configure(streamConfig);
    } on Object catch (error) {
      printWarning('This computer cannot decode the mirrored screen', error);
      if (identical(_decoder, decoder)) {
        await _finish(.decoderFailed, notify: .STOP_REASON_VIEWER_DONE);
      }

      return;
    }

    if (!identical(_decoder, decoder) || _configId != config.configId) {
      return;
    }

    _configuring = false;
    _set(_current?.copyWith(config: streamConfig));
    final held = List.of(_held);
    _held.clear();
    for (final frame in held) {
      _decode(decoder, frame);
    }
  }

  void onFrame(Session session, Frame frame) {
    final decoder = _decoder;
    if (!_isMirroring(session) || decoder == null) {
      _answerStray(session);
      return;
    }

    if (frame.configId != _configId) {
      return;
    }

    _countGap(frame.sequence);
    if (_configuring) {
      if (_held.length < _maxHeldFrames) {
        _held.add(frame);
      }

      return;
    }

    _decode(decoder, frame);
  }

  void onSourceState(Session session, SourceState state) {
    if (!_isMirroring(session)) {
      return;
    }

    _set(_current?.copyWith(screenOff: state.screenOff));
  }

  /// The phone's answer to this side's stats: the round trip and its
  /// bitrate.
  void onStats(Session session, Stats stats) {
    final current = _current;
    if (!_isMirroring(session) || current == null) {
      return;
    }

    final now = _clock().millisecondsSinceEpoch;
    final roundTripMs = now - stats.echoSentAtMs.toInt();
    final latencyMs = switch (stats.echoSentAtMs.toInt() > 0 &&
        roundTripMs >= 0) {
      true => roundTripMs ~/ 2 + _decodeMs,
      false => current.stats.latencyMs,
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

  Future<void> onStop(Session session, Stop stop) async {
    final current = _current;
    if (current == null ||
        !current.isLive ||
        current.deviceId != session.remoteDeviceId) {
      return;
    }

    await _finish(switch (stop.reason) {
      .STOP_REASON_STOPPED_ON_SOURCE => .stoppedOnPhone,
      .STOP_REASON_SYSTEM_ENDED => .systemEnded,
      .STOP_REASON_TURNED_OFF => .turnedOff,
      .STOP_REASON_NOT_MIRRORING => .lostConnection,
      _ => .failed,
    });
  }

  Future<void> onSessionClosed(String deviceId) async {
    final current = _current;
    if (current == null || !current.isLive || current.deviceId != deviceId) {
      return;
    }

    await _finish(.lostConnection);
  }

  Future<void> dispose() async {
    await stop();
    _waitTimer?.cancel();
    _statsTimer?.cancel();
    await _closeDecoder();
    _picture.dispose();
    await _changes.close();
    await _statsChanges.close();
  }

  bool _isMirroring(Session session) {
    final current = _current;
    return current != null &&
        current.isMirroring &&
        current.deviceId == session.remoteDeviceId;
  }

  void _decode(MirrorDecoder decoder, Frame frame) {
    if (_needsKeyframe && !frame.keyframe) {
      _droppedInWindow++;
      return;
    }

    if (_decodingSince.length >= maxDecoding) {
      _droppedInWindow++;
      _decodingSince.clear();
      _loseKeyframe();
      return;
    }

    _needsKeyframe = false;
    final ptsUs = frame.ptsUs.toInt();
    _decodingSince[ptsUs] = _clock();
    decoder.decode(
      MirrorFrame(
        data: Uint8List.fromList(frame.data),
        ptsUs: ptsUs,
        keyframe: frame.keyframe,
      ),
    );
  }

  void _countGap(Int64 sequence) {
    final last = _lastSequence;
    _lastSequence = sequence;
    if (last == null || sequence <= last + 1) {
      return;
    }

    _droppedInWindow += (sequence - last - 1).toInt();
  }

  void _openDecoder() {
    final decoder = _createDecoder();
    _decoder = decoder;
    decoder.picture.addListener(_onPicture);
    _decoderSubscriptions
      ..add(decoder.decoded.listen(_onDecoded))
      ..add(decoder.errors.listen((_) => _loseKeyframe()));
  }

  Future<void> _closeDecoder() async {
    final decoder = _decoder;
    final subscriptions = List.of(_decoderSubscriptions);
    _decoder = null;
    _decoderSubscriptions.clear();
    if (decoder == null) {
      return;
    }

    decoder.picture.removeListener(_onPicture);
    _picture.value = null;
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }

    try {
      await decoder.dispose();
    } on Object catch (error) {
      printWarning('Closing the mirror decoder failed', error);
    }
  }

  void _onPicture() => _picture.value = _decoder?.picture.value;

  void _onDecoded(DecodedFrame frame) {
    _shownInWindow++;
    final since = _decodingSince.remove(frame.ptsUs);
    _decodingSince.removeWhere((ptsUs, _) => ptsUs < frame.ptsUs);
    if (since != null) {
      _decodeMs = _clock().difference(since).inMilliseconds;
    }

    final current = _current;
    if (current == null || current.phase != .starting) {
      return;
    }

    _waitTimer?.cancel();
    _waitTimer = null;
    _set(current.copyWith(phase: .streaming));
  }

  /// A frame was lost: nothing decodes until the phone sends a keyframe.
  void _loseKeyframe() {
    _needsKeyframe = true;
    _decodingSince.clear();
    final current = _current;
    final now = _clock();
    final askedAt = _keyframeAskedAt;
    if (current == null ||
        !current.isMirroring ||
        (askedAt != null && now.difference(askedAt) < _keyframeRequestGap)) {
      return;
    }

    _keyframeAskedAt = now;
    unawaited(_send(current.deviceId, KeyframeRequest()));
  }

  void _onStatsTick() {
    final current = _current;
    if (current == null || !current.isMirroring) {
      return;
    }

    final shown = _shownInWindow;
    final dropped = _droppedInWindow;
    _shownInWindow = 0;
    _droppedInWindow = 0;
    _current = current.copyWith(
      stats: ViewStats(
        fps: shown,
        latencyMs: current.stats.latencyMs,
        bitrateKbps: current.stats.bitrateKbps,
        droppedFrames: dropped,
      ),
    );
    _emitStats();
    unawaited(
      _send(
        current.deviceId,
        Stats(
          sentAtMs: Int64(_clock().millisecondsSinceEpoch),
          fps: shown,
          droppedFrames: dropped,
        ),
      ),
    );
  }

  Future<void> _giveUp(int attempt, ViewEnd end) async {
    if (attempt != _attempt) {
      return;
    }

    await _finish(end, notify: .STOP_REASON_VIEWER_DONE);
  }

  Future<void> _endAttempt(int attempt, ViewEnd end) async {
    if (attempt != _attempt) {
      return;
    }

    await _finish(end);
  }

  /// Ends the current attempt: the picture goes away, the phone is told
  /// when it should stop, and a session that showed anything is recorded.
  Future<void> _finish(ViewEnd end, {StopReason? notify}) async {
    final current = _current;
    if (current == null || !current.isLive) {
      return;
    }

    _waitTimer?.cancel();
    _waitTimer = null;
    _statsTimer?.cancel();
    _statsTimer = null;
    _current = current.copyWith(phase: .ended, end: end);
    _lastEnds[current.deviceId] = end;
    final record = _recordOf(current, end);
    if (record != null) {
      _lastRecord = record;
    }

    _emit();
    if (notify != null) {
      await _send(current.deviceId, Stop(reason: notify));
    }

    await _closeDecoder();
    _resetStream();
    if (record != null) {
      await _settings.addRecord(record);
    }

    _emit();
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

  void _resetStream() {
    _configId = null;
    _configuring = false;
    _needsKeyframe = true;
    _lastSequence = null;
    _keyframeAskedAt = null;
    _shownInWindow = 0;
    _droppedInWindow = 0;
    _decodeMs = 0;
    _held.clear();
    _decodingSince.clear();
  }

  ViewEnd _endOfDeny(DenyReason reason) => switch (reason) {
    .DENY_REASON_DENIED => .denied,
    .DENY_REASON_TIMEOUT => .timedOut,
    .DENY_REASON_BUSY => .busy,
    .DENY_REASON_UNSUPPORTED => .unsupported,
    .DENY_REASON_TURNED_OFF => .turnedOff,
    .DENY_REASON_VERSION => .version,
    .DENY_REASON_NO_CODEC => .noCodec,
    .DENY_REASON_CANNOT_ASK => .cannotAsk,
    _ => .failed,
  };

  /// Frames from a phone this computer isn't watching: tells it to stop,
  /// at most once a second.
  void _answerStray(Session session) {
    final deviceId = session.remoteDeviceId;
    final now = _clock();
    final last = _strayNoticeAt[deviceId];
    if (last != null && now.difference(last) < _strayNoticeGap) {
      return;
    }

    _strayNoticeAt[deviceId] = now;
    unawaited(_send(deviceId, Stop(reason: .STOP_REASON_NOT_MIRRORING)));
  }

  Future<void> _send(String deviceId, GeneratedMessage message) async {
    final session = _host.sessionFor(deviceId);
    if (session == null) {
      return;
    }

    try {
      await session.send(_featureId, message);
    } on Object catch (error) {
      printWarning('Mirroring message to $deviceId failed', error);
    }
  }

  String _nameOf(String deviceId, Session? session) =>
      session?.remoteDevice?.name ??
      _host.trustStore[deviceId]?.name ??
      deviceId;

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
