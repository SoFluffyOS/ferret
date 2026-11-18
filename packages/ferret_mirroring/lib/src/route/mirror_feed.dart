import 'package:ferret_mirroring/src/route/mirror_control.dart';
import 'package:ferret_mirroring/src/route/mirror_target.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';

/// One device's screen arriving through a route, until it ends.
abstract interface class MirrorFeed {
  MirrorTarget get target;

  /// In order: [FeedWaiting] while the other side asks its owner, then a
  /// [FeedConfigured] before the first frame and on every size change,
  /// [FeedFrame]s, and one [FeedEnded] last.
  Stream<FeedEvent> get events;

  /// Mouse, keyboard and buttons on the other device, when the route has
  /// them and they were asked for.
  MirrorControl? get control;

  /// The next frame must decode on its own.
  Future<void> requestKeyframe();

  Future<void> setBitrate(int bitrate);

  Future<void> stop();
}

sealed class FeedEvent {
  const FeedEvent();
}

/// The other side is asking its owner, for at most [timeout].
class FeedWaiting extends FeedEvent {
  const FeedWaiting(this.timeout);

  final Duration timeout;
}

class FeedConfigured extends FeedEvent {
  const FeedConfigured(this.config);

  final MirrorStreamConfig config;
}

class FeedFrame extends FeedEvent {
  const FeedFrame(this.frame);

  final MirrorFrame frame;
}

class FeedEnded extends FeedEvent {
  const FeedEnded(this.reason, {this.detail});

  final FeedEnd reason;

  /// For logs, never shown as is.
  final String? detail;
}

/// Why a feed ended, whatever the route.
enum FeedEnd {
  stoppedHere,
  stoppedThere,
  denied,
  timedOut,
  busy,
  unsupported,
  turnedOff,
  cannotAsk,
  version,
  noCodec,
  notConnected,
  noAnswer,
  systemEnded,
  lostConnection,
  failed,
}
