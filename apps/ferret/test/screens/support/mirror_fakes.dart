// The harness may only touch test/screens, so packages the app gets through
// its modules are imported without listing them in pubspec.yaml.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:ui' as ui;

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:mirroring/mirroring.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// Just enough of the engine for the mirroring feature: settings, the
/// paired devices and who is connected.
class MirrorHost implements FeatureHost {
  MirrorHost(this.identity, this.trustStore);

  static Future<MirrorHost> create() async => MirrorHost(
    await DeviceIdentity.generate(),
    await TrustStore.open(MemorySecretStore()),
  );

  final StreamController<List<Session>> _sessionChanges = .broadcast(
    sync: true,
  );

  @override
  final DeviceIdentity identity;

  @override
  final TrustStore trustStore;

  @override
  final MemorySettingsStore settings = MemorySettingsStore();

  @override
  DeviceInfo get localDevice =>
      DeviceInfo(id: identity.deviceId, name: 'MacBook Air');

  @override
  List<Session> sessions = [];

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

/// A connected phone that offers its screen and answers requests with
/// [answer].
class MirrorSession implements Session {
  MirrorSession(this.remoteDeviceId, {required this.name, this.answer});

  @override
  final String remoteDeviceId;
  final String name;
  FutureOr<GeneratedMessage> Function(GeneratedMessage request)? answer;

  @override
  bool get isClosed => false;

  @override
  DeviceInfo? get remoteDevice => DeviceInfo(id: remoteDeviceId, name: name);

  @override
  bool get isWeak => false;

  @override
  bool supports(String featureId) => featureId == MirroringFeature.featureId;

  @override
  FeatureSupport? remoteFeature(String featureId) => FeatureSupport(
    id: featureId,
    version: 1,
    flags: const [MirroringFeature.shareFlag],
  );

  @override
  Future<void> send(String feature, GeneratedMessage message) async {}

  @override
  Future<Envelope> request(
    String feature,
    GeneratedMessage message, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
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

/// A decoder that shows one prepared image for every stream, since a test
/// has no video texture to draw.
class StillDecoder implements MirrorDecoder {
  StillDecoder(this.image);

  final ui.Image image;
  final ValueNotifier<MirrorPicture?> _picture = .new(null);
  final StreamController<DecodedFrame> _decoded = .broadcast(sync: true);

  @override
  ValueListenable<MirrorPicture?> get picture => _picture;

  @override
  Stream<DecodedFrame> get decoded => _decoded.stream;

  @override
  Stream<void> get errors => const .empty();

  @override
  Future<void> configure(MirrorStreamConfig config) async {}

  @override
  void decode(MirrorFrame frame) {
    _picture.value = ImagePicture(image);
    _decoded.add(
      DecodedFrame(
        ptsUs: frame.ptsUs,
        width: image.width,
        height: image.height,
      ),
    );
  }

  @override
  Future<bool> savePicture(String path) async => true;

  @override
  Future<void> dispose() async {}
}

class CableControl implements MirrorControl {
  @override
  Set<ControlAbility> get abilities => const {
    .pointer,
    .keys,
    .text,
    .buttons,
    .clipboard,
  };

  @override
  void pointer(MirrorPointer event) {}

  @override
  void key(MirrorKey event) {}

  @override
  void press(DeviceButton button) {}

  @override
  void text(String text) {}

  @override
  void setClipboard(String text, {bool paste = false}) {}
}

class CableFeed implements MirrorFeed {
  CableFeed(this.target, {this.control});

  @override
  final MirrorTarget target;

  @override
  final MirrorControl? control;
  final StreamController<FeedEvent> _events = .new(sync: true);

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
  Future<void> requestKeyframe() async {}

  @override
  Future<void> setBitrate(int bitrate) async {}

  @override
  Future<void> stop() async {}
}

/// A speaker that takes any sound and plays none.
class QuietSpeaker implements AudioSink {
  @override
  Future<void> configure(
    MirrorAudioConfig config, {
    bool silent = false,
  }) async {}

  @override
  void play(MirrorAudioPacket packet) {}

  @override
  void flush() {}

  @override
  void setVolume(double volume) {}

  @override
  Future<AudioSinkStats> stats() async => const AudioSinkStats();

  @override
  Future<void> dispose() async {}
}

/// The cable in memory: the screen says where it stands and what it finds.
class CableRoute implements ToolInstaller {
  final StreamController<List<MirrorTarget>> _targets = .broadcast(sync: true);
  final List<CableFeed> feeds = [];
  RouteStatus statusNow = const RouteReady();
  List<MirrorTarget> found = const [];

  @override
  String get id => 'adb';

  MirrorTarget target(String id, String name) =>
      MirrorTarget(routeId: this.id, id: id, name: name);

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
    final feed = CableFeed(target, control: CableControl());
    feeds.add(feed);
    return feed;
  }

  @override
  bool get canInstallTool => true;

  @override
  String get toolNotStartedDetail => 'adb start-server';

  @override
  Future<void> installTool() async {}

  @override
  Future<void> dispose() async {}
}

/// A receiver in memory: the screen makes a device ask to be let in.
class AirReceiver implements MirrorReceiver {
  final StreamController<MirrorFeed> _incoming = .broadcast(sync: true);
  ReceiverAllow? _allow;
  bool _listening = false;

  Future<bool> ask(String deviceName) async =>
      await _allow?.call(deviceName) ?? false;

  void receive(MirrorFeed feed) => _incoming.add(feed);

  @override
  String get id => 'airplay';

  @override
  bool get listensByDefault => false;

  @override
  Future<RouteStatus> status() async => const RouteReady();

  @override
  Future<void> start(String name, {ReceiverAllow? allow}) async {
    _listening = true;
    _allow = allow;
  }

  @override
  Future<void> stop() async => _listening = false;

  @override
  bool get isListening => _listening;

  @override
  Stream<MirrorFeed> get incoming => _incoming.stream;

  @override
  Future<void> dispose() async {}
}
