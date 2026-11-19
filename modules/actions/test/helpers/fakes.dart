import 'dart:async';
import 'dart:typed_data';

import 'package:actions/actions.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_actions/ferret_actions.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// A computer in memory: records what it was told to do, and does nothing.
class FakeComputer implements ComputerActions {
  FakeComputer({this.works = true, Set<ComputerAction>? supported})
    : supported = supported ?? ComputerAction.values.toSet();

  bool works;
  final List<ComputerAction> ran = [];

  @override
  final Set<ComputerAction> supported;

  @override
  Future<bool> run(ComputerAction action) async {
    ran.add(action);
    return works;
  }
}

/// Records each command instead of starting it, and ends it with
/// [outcome].
class FakeRunner implements CommandRunner {
  FakeRunner({this.outcome = const CommandOutcome(exitCode: 0)});

  CommandOutcome outcome;
  final List<List<String>> ran = [];
  final List<Duration> timeouts = [];

  @override
  Future<CommandOutcome> run(
    List<String> command, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    ran.add(command);
    timeouts.add(timeout);
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A connected device: records what was sent, and answers requests with
/// [answer].
class FakeSession implements Session {
  FakeSession(
    this.remoteDeviceId, {
    this.name = 'Pixel 7',
    this.flags = const [],
    this.platform = Platform.PLATFORM_ANDROID,
    this.answer,
  });

  @override
  final String remoteDeviceId;
  final String name;
  final List<String> flags;
  final Platform platform;

  /// Answers a request, or throws to fail it. Null fails with a timeout.
  FutureOr<GeneratedMessage> Function(GeneratedMessage request)? answer;
  final List<GeneratedMessage> sent = [];
  final List<GeneratedMessage> requests = [];

  List<T> sentOf<T>() => [
    for (final message in sent)
      if (message case final T typed) typed,
  ];

  @override
  GoodbyeReason? remoteGoodbye;

  @override
  bool get isClosed => false;

  @override
  DeviceInfo? get remoteDevice =>
      DeviceInfo(id: remoteDeviceId, name: name, platform: platform);

  @override
  bool supports(String featureId) => featureId == ActionsFeature.featureId;

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

  final List<GeneratedMessage> broadcasts = [];

  @override
  Presence localPresence = Presence(batteryPercent: -1);

  /// What this device is, for features that decide by platform.
  Platform platform = .PLATFORM_UNSPECIFIED;

  @override
  DeviceInfo get localDevice => DeviceInfo(
    id: identity.deviceId,
    name: 'MacBook Air',
    platform: platform,
  );

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
  Stream<List<Session>> get sessionChanges => const Stream.empty();

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {
    broadcasts.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Locks nothing: counts how often it was asked.
class FakeLocker implements ScreenLocker {
  FakeLocker({this.works = true});

  bool works;
  int locks = 0;

  @override
  bool get isSupported => true;

  @override
  Future<bool> lock() async {
    locks++;
    return works;
  }
}

/// Says the keyboard and mouse sat untouched for [idle].
class FakeIdle implements InputIdle {
  FakeIdle([this.idle = const Duration(minutes: 5)]);

  Duration? idle;

  @override
  Future<Duration?> idleTime() async => idle;
}

/// Saves [deviceId] as a paired Android phone.
Future<void> pairPhone(
  FakeHost host,
  String deviceId, {
  String name = 'Pixel 7',
}) => host.trustStore.save(
  TrustedDevice(
    id: deviceId,
    name: name,
    platform: .PLATFORM_ANDROID,
    formFactor: .FORM_FACTOR_PHONE,
    publicKey: Uint8List(32),
    pairedAt: DateTime(2026, 11, 19),
  ),
);

/// [message] as it arrives in an envelope from another device.
Envelope envelopeOf(GeneratedMessage message, {bool expectsReply = false}) =>
    Envelope(
      id: Int64(1),
      feature: ActionsFeature.featureId,
      type: message.payloadType,
      payload: message.toPayload(),
      expectsReply: expectsReply,
    );

/// Lets queued stream events and futures run.
Future<void> settle() async {
  for (var turn = 0; turn < 5; turn++) {
    await Future<void>.delayed(Duration.zero);
  }
}
