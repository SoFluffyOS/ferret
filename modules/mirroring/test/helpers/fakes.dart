import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
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

  @override
  List<Session> sessions = [];

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
  Stream<List<Session>> get sessionChanges => const .empty();

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
