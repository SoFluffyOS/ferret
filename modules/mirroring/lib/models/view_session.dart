import 'package:ferret_mirroring/ferret_mirroring.dart';

/// Where the computer stands with one phone's screen.
enum ViewPhase {
  /// The request is on its way.
  requesting,

  /// The phone is asking its owner.
  waitingForPhone,

  /// The owner said yes; no picture has arrived yet.
  starting,

  /// Pictures are showing.
  streaming,

  /// Over, or it never started: see [ViewSession.end].
  ended,
}

/// Why the computer isn't showing the phone's screen (any more).
enum ViewEnd {
  /// The owner said no on the phone's prompt.
  denied,

  /// Nobody answered on the phone in time.
  timedOut,

  /// The phone shares with another device.
  busy,

  /// The phone can't capture its screen.
  unsupported,

  /// Screen mirroring is off on the phone.
  turnedOff,

  /// The phone couldn't show the question.
  cannotAsk,

  /// The phone runs an older Ferret.
  version,

  /// The phone can't send anything this computer can decode.
  noCodec,

  /// The phone isn't connected.
  notConnected,

  /// The phone didn't answer the request, or no picture ever came.
  noAnswer,

  /// Stop or Back on this computer.
  stoppedHere,

  /// Stop on the phone.
  stoppedOnPhone,

  /// The phone's system ended the capture, such as when it was locked.
  systemEnded,

  lostConnection,

  /// The phone's capture or encoder failed.
  failed,

  /// This computer couldn't decode the stream.
  decoderFailed,

  /// The way to this device needs a step from its owner first: see
  /// [ViewSession.setup].
  needsSetup;

  /// How a feed's own ending reads on the mirror page.
  static ViewEnd ofFeed(FeedEnd end) => switch (end) {
    .stoppedHere => .stoppedHere,
    .stoppedThere => .stoppedOnPhone,
    .denied => .denied,
    .timedOut => .timedOut,
    .busy => .busy,
    .unsupported => .unsupported,
    .turnedOff => .turnedOff,
    .cannotAsk => .cannotAsk,
    .version => .version,
    .noCodec => .noCodec,
    .notConnected => .notConnected,
    .noAnswer => .noAnswer,
    .systemEnded => .systemEnded,
    .lostConnection => .lostConnection,
    .failed => .failed,
  };

  /// The same ending in a route's words. What only this computer knows
  /// about, such as its decoder, is a plain failure there.
  FeedEnd get feedEnd => switch (this) {
    .stoppedHere => .stoppedHere,
    .stoppedOnPhone => .stoppedThere,
    .denied => .denied,
    .timedOut => .timedOut,
    .busy => .busy,
    .unsupported => .unsupported,
    .turnedOff => .turnedOff,
    .cannotAsk => .cannotAsk,
    .version => .version,
    .noCodec => .noCodec,
    .notConnected => .notConnected,
    .noAnswer => .noAnswer,
    .systemEnded => .systemEnded,
    .lostConnection => .lostConnection,
    .failed || .decoderFailed || .needsSetup => .failed,
  };
}

/// The numbers on the mirror page's status line.
class ViewStats {
  const ViewStats({
    this.fps = 0,
    this.latencyMs,
    this.bitrateKbps = 0,
    this.droppedFrames = 0,
  });

  /// Pictures shown in the last second.
  final int fps;

  /// About how old a picture is when it shows: half the round trip to the
  /// phone plus the time to decode. Null until measured.
  final int? latencyMs;

  /// What the phone's encoder aims for; 0 when it doesn't say.
  final int bitrateKbps;

  /// Frames dropped in the last second, on either side.
  final int droppedFrames;
}

/// One attempt to show a phone's screen, as the mirror page follows it.
class ViewSession {
  const ViewSession({
    required this.target,
    required this.phase,
    this.end,
    this.setup,
    this.setupDetail,
    this.startedAt,
    this.config,
    this.screenOff = false,
    this.stats = const ViewStats(),
  });

  /// What the mirror page and the history know [target] by: its Ferret
  /// device id when it has one, so a phone reached another way is still
  /// the same phone.
  static String deviceIdOf(MirrorTarget target) =>
      target.ferretDeviceId ?? '${target.routeId}:${target.id}';

  /// The device being shown, and the route it comes through.
  final MirrorTarget target;
  final ViewPhase phase;

  /// Set once [phase] is [ViewPhase.ended].
  final ViewEnd? end;

  /// What the route still needs, when [end] is [ViewEnd.needsSetup].
  final RouteSetup? setup;

  /// Something the route said to show next to [setup], such as a path.
  final String? setupDetail;

  /// When the phone's owner said yes.
  final DateTime? startedAt;

  /// The stream being shown.
  final MirrorStreamConfig? config;

  /// The phone's screen is off: the picture stands still.
  final bool screenOff;
  final ViewStats stats;

  String get deviceId => deviceIdOf(target);

  String get deviceName => target.name;

  /// The phone was asked and hasn't said no or stopped.
  bool get isLive => phase != .ended;

  /// The phone is sharing its screen with this computer.
  bool get isMirroring => phase == .starting || phase == .streaming;

  ViewSession copyWith({
    ViewPhase? phase,
    ViewEnd? end,
    RouteSetup? setup,
    String? setupDetail,
    DateTime? startedAt,
    MirrorStreamConfig? config,
    bool? screenOff,
    ViewStats? stats,
  }) => ViewSession(
    target: target,
    phase: phase ?? this.phase,
    end: end ?? this.end,
    setup: setup ?? this.setup,
    setupDetail: setupDetail ?? this.setupDetail,
    startedAt: startedAt ?? this.startedAt,
    config: config ?? this.config,
    screenOff: screenOff ?? this.screenOff,
    stats: stats ?? this.stats,
  );
}
