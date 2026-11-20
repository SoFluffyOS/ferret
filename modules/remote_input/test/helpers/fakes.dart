import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:remote_input/remote_input.dart';

/// An injector in memory: records actions and releases.
class FakeInjector implements InputInjector {
  FakeInjector({this.statusNow = const .ready(.quartz)});

  InjectorStatus statusNow;
  final List<InputAction> injected = [];
  int releases = 0;
  int requests = 0;
  int settingsOpened = 0;
  bool failInject = false;
  bool disposed = false;

  @override
  Future<InjectorStatus> status() async => statusNow;

  @override
  Future<InjectorStatus> requestAccess() async {
    requests++;
    return statusNow;
  }

  @override
  Future<void> openAccessSettings() async => settingsOpened++;

  @override
  Future<void> inject(List<InputAction> actions) async {
    if (failInject) {
      throw StateError('blocked');
    }

    injected.addAll(actions);
  }

  @override
  Future<void> releaseAll() async => releases++;

  @override
  Future<void> dispose() async => disposed = true;
}

/// A connected device: records what was sent, and answers requests with
/// [answer].
class FakeSession implements Session {
  FakeSession(
    this.remoteDeviceId, {
    this.name = 'Pixel',
    this.flags = const [RemoteInputFeature.controlFlag],
    this.supported = true,
    this.answer,
    this.platform = .PLATFORM_UNSPECIFIED,
  });

  @override
  final String remoteDeviceId;
  final String name;
  final List<String> flags;
  final bool supported;
  final Platform platform;

  /// Answers a request, or throws to fail it. Null fails with a timeout.
  FutureOr<GeneratedMessage> Function(GeneratedMessage request)? answer;
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
  DeviceInfo? get remoteDevice =>
      DeviceInfo(id: remoteDeviceId, name: name, platform: platform);

  @override
  bool supports(String featureId) =>
      supported && featureId == RemoteInputFeature.featureId;

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

  @override
  DeviceInfo get localDevice =>
      DeviceInfo(id: identity.deviceId, name: 'This laptop');

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
  Future<void> broadcast(String featureId, GeneratedMessage message) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [message] as it arrives in an envelope from another device.
Envelope envelopeOf(GeneratedMessage message, {bool expectsReply = false}) =>
    Envelope(
      id: Int64(1),
      feature: RemoteInputFeature.featureId,
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

/// A Mac's event tap in memory: tests push what "was typed" through
/// [capture], and read back whether it runs.
class FakeCapture implements InputCapture {
  FakeCapture({
    this.accessNow = const CaptureAccess(
      inputMonitoring: true,
      accessibility: true,
    ),
  });

  CaptureAccess accessNow;
  CaptureAccess? accessAfterRequest;
  Set<KeyModifier> heldOnStart = const {};
  bool secureInput = false;
  bool failStart = false;
  bool keysRegistered = true;
  bool? switchKeysOn;
  bool capturing = false;
  int starts = 0;
  int stops = 0;
  int requests = 0;
  int settingsOpened = 0;

  final StreamController<List<NativeCapturedEvent>> _events = .broadcast(
    sync: true,
  );
  final StreamController<NativeSwitchKey> _switchKeys = .broadcast();
  final StreamController<NativeCaptureEnd> _ends = .broadcast();

  /// What the tap took from this Mac's keyboard and mouse.
  void capture(List<NativeCapturedEvent> events) => _events.add(events);

  void pressSwitchKey(NativeSwitchKey key) => _switchKeys.add(key);

  /// The tap stopped on its own, as for ⌃⌥⎋ or a password field.
  void end(NativeCaptureEnd reason) {
    capturing = false;
    _ends.add(reason);
  }

  @override
  Future<CaptureAccess> access() async => accessNow;

  @override
  Future<CaptureAccess> requestAccess() async {
    requests++;
    accessNow = accessAfterRequest ?? accessNow;
    return accessNow;
  }

  @override
  Future<void> openAccessSettings() async => settingsOpened++;

  @override
  Future<bool> secureInputOn() async => secureInput;

  @override
  Future<bool> setSwitchKeys({required bool enabled}) async {
    switchKeysOn = enabled;
    return !enabled || keysRegistered;
  }

  @override
  Future<Set<KeyModifier>?> start() async {
    if (failStart) {
      return null;
    }

    starts++;
    capturing = true;
    return heldOnStart;
  }

  @override
  Future<void> stop() async {
    stops++;
    capturing = false;
  }

  @override
  Stream<List<NativeCapturedEvent>> get events => _events.stream;

  @override
  Stream<NativeSwitchKey> get switchKeys => _switchKeys.stream;

  @override
  Stream<NativeCaptureEnd> get ends => _ends.stream;
}

/// One event as the Mac's tap reports it.
NativeCapturedEvent captured(
  NativeCaptureKind kind, {
  double x = 0,
  double y = 0,
  int code = 0,
  bool pressed = false,
  int modifiers = 0,
  bool isRepeat = false,
  String? text,
}) => NativeCapturedEvent(
  kind: kind,
  x: x,
  y: y,
  code: code,
  pressed: pressed,
  modifiers: modifiers,
  isRepeat: isRepeat,
  text: text,
);
