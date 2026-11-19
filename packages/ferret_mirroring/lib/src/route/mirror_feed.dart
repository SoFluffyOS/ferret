import 'package:ferret_mirroring/src/route/mirror_control.dart';
import 'package:ferret_mirroring/src/route/mirror_target.dart';
import 'package:ferret_mirroring/src/stream/mirror_audio.dart';
import 'package:ferret_mirroring/src/stream/mirror_frame.dart';
import 'package:ferret_mirroring/src/stream/mirror_stream_config.dart';

/// One device's screen arriving through a route, until it ends.
abstract interface class MirrorFeed {
  MirrorTarget get target;

  /// In order: [FeedWaiting] while the other side asks its owner, a
  /// [FeedAccepted] when it said yes, then a [FeedConfigured] before the
  /// first frame and on every size change, [FeedFrame]s, and one
  /// [FeedEnded] last. [FeedSourceState] and [FeedStats] come in between,
  /// from routes that know them. A feed asked for sound adds a
  /// [FeedAudioConfigured] and [FeedAudio]s, or one [FeedAudioUnavailable].
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

/// The owner said yes: pictures follow. Routes that never ask skip it and
/// start with [FeedConfigured].
class FeedAccepted extends FeedEvent {
  const FeedAccepted();
}

class FeedConfigured extends FeedEvent {
  const FeedConfigured(this.config);

  final MirrorStreamConfig config;
}

class FeedFrame extends FeedEvent {
  const FeedFrame(this.frame, {this.lost = 0});

  final MirrorFrame frame;

  /// Frames the route knows went missing right before this one.
  final int lost;
}

/// Sound follows, encoded this way. Again whenever it changes.
class FeedAudioConfigured extends FeedEvent {
  const FeedAudioConfigured(this.config);

  final MirrorAudioConfig config;
}

class FeedAudio extends FeedEvent {
  const FeedAudio(this.packet);

  final MirrorAudioPacket packet;
}

/// Sound was asked for and won't come. The pictures go on without it.
class FeedAudioUnavailable extends FeedEvent {
  const FeedAudioUnavailable(this.reason);

  final AudioUnavailable reason;
}

/// The other device's screen went off or came back on. While it is off,
/// the picture stands still.
class FeedSourceState extends FeedEvent {
  const FeedSourceState({required this.screenOff});

  final bool screenOff;
}

/// How the route is doing, as the other side last told it.
class FeedStats extends FeedEvent {
  const FeedStats({
    this.roundTrip,
    this.bitrateKbps = 0,
    this.droppedFrames = 0,
  });

  /// There and back to the other device, when the route measured it.
  final Duration? roundTrip;

  /// What the other side's encoder aims for; 0 when it doesn't say.
  final int bitrateKbps;

  /// Frames the other side dropped since its last report.
  final int droppedFrames;
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
