import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// A screen capture in memory: the test answers the prompt and makes the
/// frames.
class FakeCapture implements ScreenCapture {
  FakeCapture({this.supportNow = const CaptureSupport(h264: true, jpeg: true)});

  CaptureSupport supportNow;
  bool startResult = true;

  /// False keeps the prompt open after a cancel, as when the owner taps
  /// Start at the same moment.
  bool cancelClosesPrompt = true;
  final StreamController<CaptureEvent> _events = .broadcast(sync: true);
  final List<ConsentTexts> asked = [];
  final List<CaptureOptions> started = [];
  final List<int> bitrates = [];
  Completer<ConsentResult>? _consent;
  int keyframeRequests = 0;
  int stops = 0;
  int cancels = 0;
  bool disposed = false;

  /// Answers the system prompt.
  void answer(ConsentResult result) => _consent?.complete(result);

  void emit(CaptureEvent event) => _events.add(event);

  void emitFrame({bool keyframe = false, int bytes = 10, int ptsUs = 0}) =>
      emit(
        CaptureFrame(
          MirrorFrame(data: Uint8List(bytes), ptsUs: ptsUs, keyframe: keyframe),
        ),
      );

  @override
  Stream<CaptureEvent> get events => _events.stream;

  @override
  Future<CaptureSupport> support() async => supportNow;

  @override
  Future<ConsentResult> requestConsent(ConsentTexts texts, Duration timeout) {
    asked.add(texts);
    final consent = Completer<ConsentResult>();
    _consent = consent;
    return consent.future;
  }

  @override
  Future<void> cancelConsent() async {
    cancels++;
    final consent = _consent;
    if (cancelClosesPrompt && consent != null && !consent.isCompleted) {
      consent.complete(.timedOut);
    }
  }

  @override
  Future<bool> start(CaptureOptions options) async {
    started.add(options);
    return startResult;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> requestKeyframe() async => keyframeRequests++;

  @override
  Future<void> setBitrate(int bitrate) async => bitrates.add(bitrate);

  @override
  Future<void> dispose() async => disposed = true;
}

/// A decoder in memory: shows a picture for each frame when told to.
class FakeDecoder implements MirrorDecoder {
  FakeDecoder({this.failConfigure = false, this.autoShow = true});

  final bool failConfigure;

  /// Every decoded frame reaches the screen right away.
  final bool autoShow;
  final ValueNotifier<MirrorPicture?> _picture = .new(null);
  final StreamController<DecodedFrame> _decoded = .broadcast(sync: true);
  final StreamController<void> _errors = .broadcast(sync: true);
  final List<MirrorStreamConfig> configs = [];
  final List<MirrorFrame> frames = [];
  Completer<void>? configureGate;
  bool disposed = false;

  /// Where pictures were saved, and whether saving works.
  final List<String> saved = [];
  bool canSave = true;

  @override
  Future<bool> savePicture(String path) async {
    if (!canSave || _picture.value == null) {
      return false;
    }

    saved.add(path);
    return true;
  }

  void show(MirrorFrame frame) {
    final config = configs.last;
    _picture.value = TexturePicture(
      textureId: 7,
      width: config.width,
      height: config.height,
    );
    _decoded.add(
      DecodedFrame(
        ptsUs: frame.ptsUs,
        width: config.width,
        height: config.height,
      ),
    );
  }

  void fail() => _errors.add(null);

  @override
  ValueListenable<MirrorPicture?> get picture => _picture;

  @override
  Stream<DecodedFrame> get decoded => _decoded.stream;

  @override
  Stream<void> get errors => _errors.stream;

  @override
  Future<void> configure(MirrorStreamConfig config) async {
    await configureGate?.future;
    if (failConfigure) {
      throw StateError('cannot decode');
    }

    configs.add(config);
  }

  @override
  void decode(MirrorFrame frame) {
    frames.add(frame);
    if (autoShow) {
      show(frame);
    }
  }

  @override
  Future<void> dispose() async => disposed = true;
}

/// The app's windows for features, in memory: remembers what was opened
/// and every shape it was given.
class FakeWindows extends ChangeNotifier implements FeatureWindows {
  FakeWindows({this.canOpen = true});

  @override
  final bool canOpen;
  FeatureWindow? window;
  final List<Size> shapes = [];
  int broughtToFront = 0;
  int drags = 0;

  @override
  String? get openId => window?.id;

  @override
  Future<bool> open(FeatureWindow window) async {
    if (!canOpen) {
      return false;
    }

    if (this.window?.id == window.id) {
      broughtToFront++;
      return true;
    }

    this.window = window;
    shapes.add(window.contentSize);
    notifyListeners();
    return true;
  }

  @override
  Future<void> setContentSize(Size contentSize) async =>
      shapes.add(contentSize);

  @override
  Future<void> bringToFront() async => broughtToFront++;

  @override
  Future<void> startDrag() async => drags++;

  @override
  Future<void> close() async {
    window = null;
    notifyListeners();
  }
}

/// A window that remembers whether it is full screen.
class FakeWindow implements MirrorWindow {
  FakeWindow({this.can = true});

  final bool can;
  bool fullScreen = false;

  @override
  Future<bool> canFullScreen() async => can;

  @override
  Future<bool> isFullScreen() async => fullScreen;

  @override
  Future<void> setFullScreen(bool fullScreen) async =>
      this.fullScreen = fullScreen;
}

/// A connected device: records what was sent, and answers requests with
/// [answer].
class FakeSession implements Session {
  FakeSession(
    this.remoteDeviceId, {
    this.name = 'Pixel',
    this.flags = const [MirroringFeature.shareFlag],
    this.supported = true,
    this.answer,
  });

  @override
  final String remoteDeviceId;
  final String name;
  final List<String> flags;
  final bool supported;

  /// Answers a request, or throws to fail it. Null fails with a timeout.
  FutureOr<GeneratedMessage> Function(GeneratedMessage request)? answer;

  /// Holds every [send] until completed, like a connection that backs up.
  Completer<void>? sendGate;
  final List<GeneratedMessage> sent = [];
  final List<GeneratedMessage> requests = [];
  bool hasClosed = false;

  List<T> sentOf<T>() => [
    for (final message in sent)
      if (message case final T typed) typed,
  ];

  @override
  bool get isClosed => hasClosed;

  @override
  DeviceInfo? get remoteDevice => DeviceInfo(id: remoteDeviceId, name: name);

  @override
  bool supports(String featureId) =>
      supported && featureId == MirroringFeature.featureId;

  @override
  FeatureSupport? remoteFeature(String featureId) {
    if (!supports(featureId)) {
      return null;
    }

    return FeatureSupport(id: featureId, version: 1, flags: flags);
  }

  @override
  Future<void> send(String feature, GeneratedMessage message) async {
    sent.add(message);
    await sendGate?.future;
  }

  @override
  Future<Envelope> request(
    String feature,
    GeneratedMessage message, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    requests.add(message);
    final answer = this.answer;
    if (answer == null) {
      throw TimeoutException('no answer', timeout);
    }

    final reply = await answer(message);
    return Envelope(
      id: Int64(2),
      replyTo: Int64(1),
      feature: feature,
      type: reply.payloadType,
      payload: reply.toPayload(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Just enough of the engine for the feature: settings and sessions.
class FakeHost implements FeatureHost {
  FakeHost(this.identity, this.trustStore, {Map<String, Object?>? settings})
    : settings = MemorySettingsStore(settings);

  static Future<FakeHost> create({Map<String, Object?>? settings}) async =>
      FakeHost(
        await DeviceIdentity.generate(),
        await TrustStore.open(MemorySecretStore()),
        settings: settings,
      );

  @override
  final DeviceIdentity identity;

  @override
  final TrustStore trustStore;

  @override
  final MemorySettingsStore settings;

  @override
  DeviceInfo get localDevice =>
      DeviceInfo(id: identity.deviceId, name: 'This device');

  final StreamController<List<Session>> _sessionChanges = .broadcast(
    sync: true,
  );

  @override
  List<Session> sessions = [];

  /// Connects or drops devices, and tells whoever follows the sessions.
  void setSessions(List<Session> now) {
    sessions = now;
    _sessionChanges.add(now);
  }

  @override
  Session? sessionFor(String deviceId) {
    for (final session in sessions) {
      if (session.remoteDeviceId == deviceId) {
        return session;
      }
    }

    return null;
  }

  @override
  Stream<List<Session>> get sessionChanges => _sessionChanges.stream;

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [message] as it arrives in an envelope from another device.
Envelope envelopeOf(GeneratedMessage message, {bool expectsReply = false}) =>
    Envelope(
      id: Int64(1),
      feature: MirroringFeature.featureId,
      type: message.payloadType,
      payload: message.toPayload(),
      expectsReply: expectsReply,
    );

/// The words a test phone puts on its notices.
ConsentTexts textsFor(String deviceName) => ConsentTexts(
  askTitle: '$deviceName wants to see this screen',
  askBody: 'Tap to answer',
  askChannelName: 'Requests',
  sharingTitle: 'Sharing screen with $deviceName',
  sharingBody: 'Visible there',
  stopLabel: 'Stop',
  sharingChannelName: 'Sharing',
);

/// Lets queued stream events and futures run.
Future<void> settle() async {
  for (var turn = 0; turn < 5; turn++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A way to control a device that remembers what it was told.
class FakeControl implements MirrorControl {
  FakeControl({
    this.abilities = const {
      ControlAbility.pointer,
      ControlAbility.keys,
      ControlAbility.buttons,
    },
  });

  @override
  final Set<ControlAbility> abilities;
  final List<MirrorPointer> pointers = [];
  final List<MirrorKey> keys = [];
  final List<DeviceButton> pressed = [];
  final List<String> typed = [];
  final List<String> pasted = [];

  @override
  void pointer(MirrorPointer event) => pointers.add(event);

  @override
  void key(MirrorKey event) => keys.add(event);

  @override
  void press(DeviceButton button) => pressed.add(button);

  @override
  void text(String text) => typed.add(text);

  @override
  void setClipboard(String text, {bool paste = false}) => pasted.add(text);
}

/// A feed the test drives by hand.
class FakeFeed implements MirrorFeed {
  FakeFeed(this.target, {this.control});

  @override
  final MirrorTarget target;

  @override
  final MirrorControl? control;
  final StreamController<FeedEvent> _events = .new(sync: true);
  int keyframeRequests = 0;
  int stops = 0;

  void emit(FeedEvent event) => _events.add(event);

  /// A config and a first keyframe, as a route without a prompt starts.
  void play({int width = 1080, int height = 2400}) {
    emit(
      FeedConfigured(
        MirrorStreamConfig(codec: .h264, width: width, height: height),
      ),
    );
    emit(FeedFrame(MirrorFrame(data: Uint8List(1), ptsUs: 0, keyframe: true)));
  }

  @override
  Stream<FeedEvent> get events => _events.stream;

  @override
  Future<void> requestKeyframe() async => keyframeRequests++;

  @override
  Future<void> setBitrate(int bitrate) async {}

  @override
  Future<void> stop() async => stops++;
}

/// A route in memory: the test says where it stands and what it finds.
class FakeRoute implements MirrorRoute {
  FakeRoute(this.id, {this.statusNow = const RouteReady(), this.control});

  @override
  final String id;
  RouteStatus statusNow;
  final MirrorControl? control;
  final StreamController<List<MirrorTarget>> _targets = .broadcast(sync: true);
  final List<FakeFeed> feeds = [];
  final List<FeedOptions> options = [];
  List<MirrorTarget> found = const [];
  bool failOpen = false;
  bool disposed = false;

  MirrorTarget target(String id, String name, {String? ferretDeviceId}) =>
      MirrorTarget(
        routeId: this.id,
        id: id,
        name: name,
        ferretDeviceId: ferretDeviceId,
      );

  void find(List<MirrorTarget> targets) {
    found = targets;
    _targets.add(targets);
  }

  @override
  Future<RouteStatus> status() async => statusNow;

  @override
  Stream<List<MirrorTarget>> get targets async* {
    yield found;
    yield* _targets.stream;
  }

  @override
  Future<MirrorFeed> open(MirrorTarget target, FeedOptions options) async {
    if (failOpen) {
      throw StateError('cannot open');
    }

    this.options.add(options);
    final feed = FakeFeed(target, control: control);
    feeds.add(feed);
    return feed;
  }

  @override
  Future<void> dispose() async => disposed = true;
}

/// A receiver in memory: the test makes devices show up on it.
class FakeReceiver implements MirrorReceiver {
  FakeReceiver(
    this.id, {
    this.statusNow = const RouteReady(),
    this.listensByDefault = true,
  });

  @override
  final String id;
  RouteStatus statusNow;
  final StreamController<MirrorFeed> _incoming = .broadcast(sync: true);
  String? listeningAs;
  ReceiverAllow? _allow;
  bool disposed = false;

  @override
  final bool listensByDefault;

  void receive(MirrorFeed feed) => _incoming.add(feed);

  /// A device asks to be let in, as it would over the network.
  Future<bool> ask(String deviceName) async =>
      await _allow?.call(deviceName) ?? false;

  @override
  Future<RouteStatus> status() async => statusNow;

  @override
  Future<void> start(String name, {ReceiverAllow? allow}) async {
    listeningAs = name;
    _allow = allow;
  }

  @override
  Future<void> stop() async => listeningAs = null;

  @override
  bool get isListening => listeningAs != null;

  @override
  Stream<MirrorFeed> get incoming => _incoming.stream;

  @override
  Future<void> dispose() async => disposed = true;
}

/// A route that can download the tool it misses, like adb's. The test
/// says whether it may, and whether the download works.
class FakeToolRoute extends FakeRoute implements ToolInstaller {
  FakeToolRoute(super.id, {super.control});

  static const String notStarted = 'start it yourself';

  @override
  bool canInstallTool = true;

  @override
  String get toolNotStartedDetail => notStarted;

  Completer<void>? download;
  bool failDownload = false;
  int installs = 0;

  @override
  Future<void> installTool() async {
    installs++;
    if (failDownload) {
      throw StateError('offline');
    }

    if (download case final pending?) {
      await pending.future;
    }

    statusNow = const RouteReady();
  }
}

/// Pairs [deviceId] in [store] and names it [nickname] on this device only.
Future<void> nameHere(
  TrustStore store,
  String deviceId,
  String nickname,
) async {
  await store.save(
    TrustedDevice(
      id: deviceId,
      name: deviceId,
      platform: .PLATFORM_ANDROID,
      formFactor: .FORM_FACTOR_PHONE,
      publicKey: Uint8List(32),
      pairedAt: DateTime(2026, 11),
    ),
  );
  await store.rename(deviceId, nickname);
}
