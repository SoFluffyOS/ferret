import 'dart:async';

import 'package:ferret_mirroring/ferret_mirroring.dart';

/// One iPhone's screen arriving over AirPlay. Events wait until someone
/// listens, so nothing is lost between the feed being announced and the
/// viewer picking it up.
class AirPlayFeed implements MirrorFeed {
  AirPlayFeed({required this.target, required Future<void> Function() onStop})
    : _onStop = onStop;

  final Future<void> Function() _onStop;
  final StreamController<FeedEvent> _events = .new();
  bool _ended = false;

  @override
  final MirrorTarget target;

  @override
  Stream<FeedEvent> get events => _events.stream;

  /// AirPlay mirroring only shows; it has no way to control the phone.
  @override
  MirrorControl? get control => null;

  bool get isEnded => _ended;

  /// The phone decides when it sends a keyframe; there is no way to ask.
  @override
  Future<void> requestKeyframe() async {}

  /// The phone picks its own bitrate.
  @override
  Future<void> setBitrate(int bitrate) async {}

  @override
  Future<void> stop() async {
    end(.stoppedHere);
    await _onStop();
  }

  void add(FeedEvent event) {
    if (_ended) {
      return;
    }

    if (event case FeedEnded(:final reason, :final detail)) {
      end(reason, detail: detail);
      return;
    }

    _events.add(event);
  }

  /// Ends the feed once; later calls change nothing.
  void end(FeedEnd reason, {String? detail}) {
    if (_ended) {
      return;
    }

    _ended = true;
    _events.add(FeedEnded(reason, detail: detail));
    unawaited(_events.close());
  }
}
