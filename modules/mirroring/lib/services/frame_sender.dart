import 'dart:async';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/mirroring.dart';

/// Sends frames without letting them pile up. Each frame is on its way
/// until the connection took it; while too many are, new ones are dropped.
///
/// A video frame builds on the one before it, so after one is dropped the
/// rest are useless until a keyframe: they are dropped too, and the encoder
/// is asked for a keyframe as soon as the connection has caught up.
class FrameSender {
  FrameSender({
    required Future<void> Function(Frame frame) send,
    required void Function() requestKeyframe,
    this.maxPendingFrames = 6,
    this.maxPendingBytes = 768 * 1024,
    this.maxPendingKeyframes = 2,
  }) : _send = send,
       _requestKeyframe = requestKeyframe;

  /// Frames on their way at which the next one is dropped.
  final int maxPendingFrames;

  /// Bytes on their way at which the next frame is dropped.
  final int maxPendingBytes;

  /// A keyframe is big; it is only dropped when this many frames are
  /// already on their way.
  final int maxPendingKeyframes;

  final Future<void> Function(Frame frame) _send;
  final void Function() _requestKeyframe;

  int _configId = 0;
  int _sequence = 0;
  int _pendingFrames = 0;
  int _pendingBytes = 0;
  int _sent = 0;
  int _dropped = 0;
  bool _waitingForKeyframe = false;
  bool _askedForKeyframe = false;

  int get pendingFrames => _pendingFrames;

  /// The connection has more waiting than it should.
  bool get isBackedUp =>
      _pendingFrames >= maxPendingFrames || _pendingBytes >= maxPendingBytes;

  /// Frames are being dropped until the next keyframe.
  bool get isWaitingForKeyframe => _waitingForKeyframe;

  /// Frames sent and dropped since the last call, for the stats.
  ({int sent, int dropped}) takeCounts() {
    final counts = (sent: _sent, dropped: _dropped);
    _sent = 0;
    _dropped = 0;
    return counts;
  }

  /// A new stream config: its frames carry [configId], and the first one
  /// sent must be a keyframe.
  void startConfig(int configId) {
    _configId = configId;
    _waitingForKeyframe = true;
    _askedForKeyframe = true;
  }

  /// Sends [frame] or drops it. Returns whether it was sent.
  bool offer(MirrorFrame frame) {
    final sequence = _sequence++;
    if (!_shouldSend(frame)) {
      _dropped++;
      _waitingForKeyframe = true;
      if (frame.keyframe) {
        _askedForKeyframe = false;
      }

      _askForKeyframeWhenClear();
      return false;
    }

    _waitingForKeyframe = false;
    _askedForKeyframe = false;
    _pendingFrames++;
    _pendingBytes += frame.data.length;
    _sent++;
    unawaited(_deliver(frame, sequence));
    return true;
  }

  bool _shouldSend(MirrorFrame frame) {
    if (frame.keyframe) {
      return _pendingFrames < maxPendingKeyframes || !isBackedUp;
    }

    return !_waitingForKeyframe && !isBackedUp;
  }

  Future<void> _deliver(MirrorFrame frame, int sequence) async {
    try {
      await _send(
        Frame(
          configId: _configId,
          sequence: Int64(sequence),
          ptsUs: Int64(frame.ptsUs),
          keyframe: frame.keyframe,
          data: frame.data,
        ),
      );
    } on Object {
      _waitingForKeyframe = true;
    } finally {
      _pendingFrames--;
      _pendingBytes -= frame.data.length;
      _askForKeyframeWhenClear();
    }
  }

  /// One request per gap, and only once the connection can take the answer.
  void _askForKeyframeWhenClear() {
    if (!_waitingForKeyframe || _askedForKeyframe || isBackedUp) {
      return;
    }

    _askedForKeyframe = true;
    _requestKeyframe();
  }
}
