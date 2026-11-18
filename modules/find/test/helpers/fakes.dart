import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/find.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// A ringer in memory: records alerts and volume changes, and lets tests
/// stop it the way the platform would.
class FakeFindPlatform implements FindPlatform {
  FakeFindPlatform({
    this.abilitiesNow = const RingAbilities(
      controlsVolume: true,
      needsDndAccess: true,
      dndAccessGranted: true,
      hasTorch: true,
      showsOwnAlert: true,
    ),
    this.audio = const AudioState(
      volume: 3,
      maxVolume: 7,
      interruptionFilter: 2,
      quiet: true,
    ),
  });

  RingAbilities abilitiesNow;

  /// What the device's output is at now; applying a state changes it.
  AudioState? audio;
  final List<AudioState> applied = [];
  final List<RingAlert> alerts = [];
  int stopCount = 0;
  int dndOpened = 0;
  int fullScreenOpened = 0;
  bool failStart = false;
  bool failOpen = false;
  RingAlert? playing;
  final StreamController<AlertStop> _stops = .broadcast();

  /// The person tapped "Found it" or pressed a volume key on the device.
  void stopOnDevice(AlertStop stop) {
    playing = null;
    _stops.add(stop);
  }

  @override
  Stream<AlertStop> get stops => _stops.stream;

  @override
  Future<RingAbilities> abilities() async => abilitiesNow;

  @override
  Future<AudioState?> readAudio() async => audio;

  @override
  Future<void> applyAudio(AudioState state) async {
    applied.add(state);
    audio = AudioState(
      volume: state.volume,
      maxVolume: state.maxVolume,
      muted: state.muted,
      interruptionFilter: state.interruptionFilter,
      quiet: audio?.quiet ?? false,
    );
  }

  @override
  Future<void> startAlert(RingAlert alert) async {
    if (failStart) {
      throw StateError('no sound');
    }

    alerts.add(alert);
    playing = alert;
  }

  @override
  Future<void> stopAlert() async {
    stopCount++;
    playing = null;
  }

  @override
  Future<void> openDndAccessSettings() async {
    if (failOpen) {
      throw StateError('no settings');
    }

    dndOpened++;
  }

  @override
  Future<void> openFullScreenSettings() async => fullScreenOpened++;
}

/// A connected device: records what was sent, and answers requests with
/// [answer].
class FakeSession implements Session {
  FakeSession(
    this.remoteDeviceId, {
    this.name = 'Pixel',
    this.supportsFind = true,
    this.answer,
  });

  @override
  final String remoteDeviceId;
  final String name;
  final bool supportsFind;

  /// Answers a request, or throws to fail it. Null fails with a timeout.
  FutureOr<GeneratedMessage> Function(GeneratedMessage request)? answer;
  final List<GeneratedMessage> sent = [];
  final List<GeneratedMessage> requests = [];
  bool hasClosed = false;

  @override
  bool get isClosed => hasClosed;

  @override
  DeviceInfo? get remoteDevice => DeviceInfo(id: remoteDeviceId, name: name);

  @override
  bool supports(String featureId) =>
      supportsFind && featureId == FindFeature.featureId;

  @override
  Future<void> send(String feature, GeneratedMessage message) async {
    sent.add(message);
  }

  @override
  Future<T> call<T extends GeneratedMessage>(
    String feature,
    GeneratedMessage message,
    T Function() create, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    requests.add(message);
    final answer = this.answer;
    if (answer == null) {
      throw TimeoutException('no answer', timeout);
    }

    final reply = await answer(message);
    return create()..mergeFromBuffer(reply.writeToBuffer());
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
      DeviceInfo(id: identity.deviceId, name: 'This laptop');

  @override
  List<Session> sessions = [];

  final List<GeneratedMessage> broadcasts = [];

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
  Stream<List<Session>> get sessionChanges => const Stream.empty();

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {
    broadcasts.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [message] as it arrives in an envelope from another device.
Envelope envelopeOf(GeneratedMessage message, {bool expectsReply = true}) =>
    Envelope(
      id: Int64(1),
      feature: FindFeature.featureId,
      type: message.payloadType,
      payload: message.toPayload(),
      expectsReply: expectsReply,
    );

/// Starts a [FindFeature] on [host] with [platform].
Future<FindFeature> startFeature(
  FakeHost host,
  FakeFindPlatform platform, {
  DateTime Function()? clock,
}) async {
  final feature = FindFeature(platform: () => platform, clock: clock);
  await feature.start(host);
  return feature;
}

/// Lets queued stream events and futures run.
Future<void> settle() async {
  for (var turn = 0; turn < 5; turn++) {
    await Future<void>.delayed(Duration.zero);
  }
}
