import 'package:ferret_mirroring/src/capture/camera_capture.dart';
import 'package:ferret_mirroring/src/route/control_access.dart';
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
  /// A feed that is also [ControlAsking] says where control stands with
  /// [FeedControlChanged]. A feed of a camera says which one is on with
  /// [FeedCameraChanged].
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

/// Whether the device lets this computer control it changed, as its
/// owner answered or set it up. [control] follows it.
class FeedControlChanged extends FeedEvent {
  const FeedControlChanged(this.access, {this.timeout = Duration.zero});

  final ControlAccess access;

  /// With [ControlAccess.asking]: how long the owner has to answer.
  final Duration timeout;
}

/// The device's camera [lens] is on, out of [lenses]. Again whenever
/// that changes.
class FeedCameraChanged extends FeedEvent {
  const FeedCameraChanged(this.lens, {this.lenses = const []});

  final MirrorLens lens;

  /// Every camera [CameraSwitching.setLens] can pick.
  final List<MirrorLens> lenses;
}

/// A feed of a device's camera that can switch to another of its cameras.
abstract interface class CameraSwitching {
  /// Asks for [lens]. A [FeedCameraChanged] says how it went.
  Future<void> setLens(MirrorLens lens);
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
