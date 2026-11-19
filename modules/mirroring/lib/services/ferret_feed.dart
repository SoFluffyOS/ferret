import 'dart:async';
import 'dart:typed_data';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mirroring/services/mirror_protocol.dart';
import 'package:mirroring/services/viewer_stats_sink.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';

enum _FeedState { requesting, waiting, mirroring, ended }

/// One phone's screen arriving over Ferret's own session: the messages of
/// `ferret.mirroring.v1` turned into feed events, and back.
class FerretFeed implements MirrorFeed, ViewerStatsSink {
  FerretFeed({
    required this.target,
    required Future<void> Function(GeneratedMessage message) send,
    required DateTime Function() clock,
    required void Function(FerretFeed feed) onEnded,
    this.wantsSound = false,
  }) : _send = send,
       _clock = clock,
       _onEnded = onEnded;

  @override
  final MirrorTarget target;

  /// The phone was asked for its sound too.
  final bool wantsSound;

  final Future<void> Function(GeneratedMessage message) _send;
  final DateTime Function() _clock;
  final void Function(FerretFeed feed) _onEnded;

  /// Synchronous, so the viewer has handled a message by the time the
  /// next one from the phone is looked at.
  final StreamController<FeedEvent> _events = .new(sync: true);

  _FeedState _state = .requesting;
  int? _configId;
  Int64? _lastSequence;

  @override
  Stream<FeedEvent> get events => _events.stream;

  /// View only: typing and clicking on a phone is Remote input's job.
  @override
  MirrorControl? get control => null;

  bool get isEnded => _state == .ended;

  /// The phone is asking its owner, for at most [timeout].
  void waiting(Duration timeout) {
    if (_state != .requesting) {
      return;
    }

    _state = .waiting;
    _events.add(FeedWaiting(timeout));
  }

  /// False for a yes nobody waits for any more. A phone that kept its
  /// capture through a dropped connection says yes at once, sometimes
  /// before its answer to the request is read.
  bool onAccept(StartAccept accept) {
    if (_state != .waiting && _state != .requesting) {
      return false;
    }

    _state = .mirroring;
    _events.add(const FeedAccepted());
    if (!wantsSound) {
      return true;
    }

    // A phone that never heard of sound leaves the answer unset.
    switch (accept.audio) {
      case .AUDIO_ANSWER_SENDING:
        break;
      case .AUDIO_ANSWER_OFF:
        _events.add(const FeedAudioUnavailable(.notAllowed));
      default:
        _events.add(const FeedAudioUnavailable(.unsupported));
    }

    return true;
  }

  void onAudioConfig(AudioConfig config) {
    if (_state != .mirroring || !wantsSound) {
      return;
    }

    final codec = MirrorProtocol.audioFromProto(config.codec);
    if (codec == null || config.sampleRate == 0 || config.channels == 0) {
      _events.add(const FeedAudioUnavailable(.failed));
      return;
    }

    _events.add(
      FeedAudioConfigured(
        MirrorAudioConfig(
          codec: codec,
          sampleRate: config.sampleRate,
          channels: config.channels,
        ),
      ),
    );
  }

  /// False for sound nobody listens to: the phone should stop sending.
  bool onAudioFrame(AudioFrame frame) {
    if (_state != .mirroring) {
      return false;
    }

    if (!wantsSound) {
      return true;
    }

    _events.add(
      FeedAudio(
        MirrorAudioPacket(
          data: Uint8List.fromList(frame.data),
          ptsUs: frame.ptsUs.toInt(),
        ),
      ),
    );
    return true;
  }

  void onAudioEnded() {
    if (_state != .mirroring || !wantsSound) {
      return;
    }

    _events.add(const FeedAudioUnavailable(.failed));
  }

  void onDeny(DenyReason reason) {
    if (_state != .waiting) {
      return;
    }

    end(endOfDeny(reason));
  }

  void onConfig(StreamConfig config) {
    if (_state != .mirroring) {
      return;
    }

    final codec = MirrorProtocol.fromProto(config.codec);
    if (codec == null) {
      unawaited(_send(Stop(reason: .STOP_REASON_VIEWER_DONE)));
      end(.noCodec, detail: 'unknown codec ${config.codec.value}');
      return;
    }

    _configId = config.configId;
    _events.add(
      FeedConfigured(
        MirrorStreamConfig(
          codec: codec,
          width: config.width,
          height: config.height,
          rotation: config.rotation,
          fps: config.fps,
          sps: Uint8List.fromList(config.sps),
          pps: Uint8List.fromList(config.pps),
        ),
      ),
    );
  }

  /// False for a frame nobody watches: the phone should stop sending.
  bool onFrame(Frame frame) {
    if (_state != .mirroring) {
      return false;
    }

    if (frame.configId != _configId) {
      return true;
    }

    _events.add(
      FeedFrame(
        MirrorFrame(
          data: Uint8List.fromList(frame.data),
          ptsUs: frame.ptsUs.toInt(),
          keyframe: frame.keyframe,
        ),
        lost: _lostBefore(frame.sequence),
      ),
    );
    return true;
  }

  void onSourceState(SourceState state) {
    if (_state != .mirroring) {
      return;
    }

    _events.add(FeedSourceState(screenOff: state.screenOff));
  }

  /// The phone's answer to [reportStats]: its bitrate, and the echo the
  /// round trip is measured from.
  void onStats(Stats stats) {
    if (_state != .mirroring) {
      return;
    }

    final echoedMs = stats.echoSentAtMs.toInt();
    final roundTripMs = _clock().millisecondsSinceEpoch - echoedMs;
    final roundTrip = switch (echoedMs > 0 && roundTripMs >= 0) {
      true => Duration(milliseconds: roundTripMs),
      false => null,
    };
    _events.add(
      FeedStats(
        roundTrip: roundTrip,
        bitrateKbps: stats.bitrateKbps,
        droppedFrames: stats.droppedFrames,
      ),
    );
  }

  void onStop(StopReason reason) => end(switch (reason) {
    .STOP_REASON_STOPPED_ON_SOURCE => .stoppedThere,
    .STOP_REASON_SYSTEM_ENDED => .systemEnded,
    .STOP_REASON_TURNED_OFF => .turnedOff,
    .STOP_REASON_NOT_MIRRORING => .lostConnection,
    _ => .failed,
  });

  /// Ends the feed without telling the phone: it said so itself, or it is
  /// gone.
  void end(FeedEnd reason, {String? detail}) {
    if (isEnded) {
      return;
    }

    _state = .ended;
    _onEnded(this);
    _events.add(FeedEnded(reason, detail: detail));
    unawaited(_events.close());
  }

  @override
  Future<void> requestKeyframe() async {
    if (_state != .mirroring) {
      return;
    }

    await _send(KeyframeRequest());
  }

  /// The phone picks its own bitrate from the stats it is sent.
  @override
  Future<void> setBitrate(int bitrate) async {}

  @override
  void reportStats({
    required DateTime sentAt,
    required int fps,
    required int droppedFrames,
  }) {
    if (_state != .mirroring) {
      return;
    }

    unawaited(
      _send(
        Stats(
          sentAtMs: Int64(sentAt.millisecondsSinceEpoch),
          fps: fps,
          droppedFrames: droppedFrames,
        ),
      ),
    );
  }

  /// Tells the phone to stop, or to take its question back.
  @override
  Future<void> stop() async {
    if (isEnded) {
      return;
    }

    _state = .ended;
    _onEnded(this);
    await _send(Stop(reason: .STOP_REASON_VIEWER_DONE));
    _events.add(const FeedEnded(.stoppedHere));
    unawaited(_events.close());
  }

  static FeedEnd endOfDeny(DenyReason reason) => switch (reason) {
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

  int _lostBefore(Int64 sequence) {
    final last = _lastSequence;
    _lastSequence = sequence;
    if (last == null || sequence <= last + 1) {
      return 0;
    }

    return (sequence - last - 1).toInt();
  }
}
