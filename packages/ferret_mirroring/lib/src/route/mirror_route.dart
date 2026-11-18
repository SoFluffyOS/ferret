import 'package:ferret_mirroring/src/route/mirror_feed.dart';
import 'package:ferret_mirroring/src/route/mirror_target.dart';
import 'package:ferret_mirroring/src/stream/mirror_codec.dart';

/// One way to show another device's screen on this one: Ferret's own
/// session, adb with scrcpy's server, or anything that comes later. Each
/// route is replaceable; the viewer only knows this interface.
abstract interface class MirrorRoute {
  /// Stable and short, such as `ferret` or `adb`. Kept in settings and logs.
  String get id;

  /// Whether this route can work here at all, and what is missing.
  Future<RouteStatus> status();

  /// The devices this route can show right now. Emits the current list on
  /// listen, then on every change.
  Stream<List<MirrorTarget>> get targets;

  /// Starts showing [target]. The feed reports how it went, including a
  /// refusal on the other side, through its events.
  Future<MirrorFeed> open(MirrorTarget target, FeedOptions options);

  Future<void> dispose();
}

/// A route the other device starts, such as an AirPlay receiver: this side
/// only listens and takes what comes.
abstract interface class MirrorReceiver {
  String get id;

  Future<RouteStatus> status();

  /// Whether this receiver listens before its owner says anything, once
  /// receivers are allowed at all. False where the system already does the
  /// same job, such as AirPlay on a Mac.
  bool get listensByDefault;

  /// Starts listening under [name], the name the other device lists.
  /// Every device that wants to show its screen goes through [allow]
  /// first; without one, the receiver decides by itself.
  Future<void> start(String name, {ReceiverAllow? allow});

  Future<void> stop();

  bool get isListening;

  /// A device started showing its screen here.
  Stream<MirrorFeed> get incoming;

  Future<void> dispose();
}

/// Asks this computer's owner whether the device calling itself
/// [deviceName] may show its screen here. The name is only what the device
/// claims.
typedef ReceiverAllow = Future<bool> Function(String deviceName);

/// What a route needs from the viewer.
class FeedOptions {
  const FeedOptions({
    required this.codecs,
    this.maxSize = 0,
    this.maxFps = 60,
    this.bitrate = 0,
    this.audio = false,
    this.control = false,
  });

  /// What this computer can decode, best first.
  final List<MirrorCodec> codecs;

  /// Longest side in pixels, 0 for the device's own size.
  final int maxSize;
  final int maxFps;

  /// Bits per second, 0 for the route's default.
  final int bitrate;

  /// Ask for sound too, where the route has it.
  final bool audio;

  /// Ask for a way to control the device, where the route has one.
  final bool control;
}

/// Where a route stands on this device.
sealed class RouteStatus {
  const RouteStatus();
}

class RouteReady extends RouteStatus {
  const RouteReady();
}

/// The route works here once [step] is done.
class RouteNeedsSetup extends RouteStatus {
  const RouteNeedsSetup(this.step, {this.detail});

  final RouteSetup step;

  /// Something to show next to the step, such as a tool's path.
  final String? detail;
}

class RouteUnsupported extends RouteStatus {
  const RouteUnsupported();
}

/// What a route still needs, said in the module's own words.
enum RouteSetup {
  /// A helper tool, such as adb, isn't on this computer yet.
  installTool,

  /// The other device has to turn on debugging (USB or wireless).
  enableDebugging,

  /// The other device has to allow this computer.
  authorizeComputer,

  /// The system has to allow this app, such as local network access.
  grantPermission,
}
