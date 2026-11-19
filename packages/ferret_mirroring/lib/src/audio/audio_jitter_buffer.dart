import 'package:ferret_mirroring/src/stream/mirror_audio.dart';

/// What to do with the sound that just arrived.
class JitterVerdict {
  const JitterVerdict({this.play = const [], this.flush = false});

  /// Throw away what the sink still holds first: it fell too far behind.
  final bool flush;

  /// Hand these to the sink now, in order.
  final List<MirrorAudioPacket> play;
}

/// Smooths out the uneven pace sound arrives at. It holds packets until
/// [target] of sound is waiting, then lets them through as they come,
/// and keeps count of how much the sink has left to play. When the sink
/// runs dry it fills up again; when more than [max] waits, the backlog is
/// dropped, so the sound never trails the picture by more than that.
///
/// It doesn't play anything itself: it only says what to hand to a sink
/// that plays whatever it is given, back to back.
class AudioJitterBuffer {
  AudioJitterBuffer({
    required DateTime Function() clock,
    this.target = const Duration(milliseconds: 80),
    this.max = const Duration(milliseconds: 240),
    this.lateAfter = const Duration(milliseconds: 400),
  }) : _clock = clock;

  /// How much sound waits before playing starts, and after every gap.
  final Duration target;

  /// The most sound that may wait. More than this is dropped.
  final Duration max;

  /// A packet captured this long before the picture shown now is dropped:
  /// playing it would only put the sound further behind.
  final Duration lateAfter;

  final DateTime Function() _clock;
  final List<MirrorAudioPacket> _held = [];

  Duration _heldDuration = Duration.zero;
  DateTime? _playsUntil;
  int _dropped = 0;
  int _underruns = 0;

  /// Packets thrown away since the start: late ones, and backlogs.
  int get dropped => _dropped;

  /// How many times the sink ran dry after it started playing.
  int get underruns => _underruns;

  bool get isPlaying => _playsUntil != null;

  /// How much sound waits right now, here and in the sink.
  Duration get level {
    final playsUntil = _playsUntil;
    if (playsUntil == null) {
      return _heldDuration;
    }

    final left = playsUntil.difference(_clock());
    if (left.isNegative) {
      return Duration.zero;
    }

    return left;
  }

  /// Takes a packet that plays for [duration]. [videoPtsUs] is the time
  /// of the picture shown right now, on the packet's own clock, when the
  /// feed has one.
  JitterVerdict add(
    MirrorAudioPacket packet,
    Duration duration, {
    int? videoPtsUs,
  }) {
    if (duration <= Duration.zero) {
      return const JitterVerdict();
    }

    if (videoPtsUs != null &&
        videoPtsUs - packet.ptsUs > lateAfter.inMicroseconds) {
      _dropped++;
      return const JitterVerdict();
    }

    final now = _clock();
    final playsUntil = _playsUntil;
    if (playsUntil == null) {
      return _hold(packet, duration, now, flush: false);
    }

    if (!playsUntil.isAfter(now)) {
      _underruns++;
      _playsUntil = null;
      return _hold(packet, duration, now, flush: false);
    }

    if (playsUntil.difference(now) + duration > max) {
      _dropped += _backlogPackets(playsUntil.difference(now), duration);
      _playsUntil = null;
      return _hold(packet, duration, now, flush: true);
    }

    _playsUntil = playsUntil.add(duration);
    return JitterVerdict(play: [packet]);
  }

  /// Forgets everything, as for a new stream.
  void reset() {
    _held.clear();
    _heldDuration = Duration.zero;
    _playsUntil = null;
  }

  JitterVerdict _hold(
    MirrorAudioPacket packet,
    Duration duration,
    DateTime now, {
    required bool flush,
  }) {
    _held.add(packet);
    _heldDuration += duration;
    if (_heldDuration < target) {
      return JitterVerdict(flush: flush);
    }

    final play = List.of(_held);
    _playsUntil = now.add(_heldDuration);
    _held.clear();
    _heldDuration = Duration.zero;
    return JitterVerdict(play: play, flush: flush);
  }

  int _backlogPackets(Duration backlog, Duration packetDuration) =>
      backlog.inMicroseconds ~/ packetDuration.inMicroseconds;
}
