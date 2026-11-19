import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_wake/ferret_wake.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// Records packets instead of sending them. [refusesBroadcast] plays an
/// iPhone without the multicast entitlement.
class FakeSender implements WakeSender {
  FakeSender({this.refusesBroadcast = false, this.refusesAll = false});

  final bool refusesBroadcast;
  final bool refusesAll;
  final List<List<WakePacket>> sends = [];

  @override
  Future<List<WakePacket>> send(List<WakePacket> packets) async {
    sends.add(packets);
    if (refusesAll) {
      return const [];
    }

    return [
      for (final packet in packets)
        if (!refusesBroadcast || !packet.isBroadcast) packet,
    ];
  }
}

/// A connected device: records what was sent, and answers wake requests
/// with [answer].
class FakeSession implements Session {
  FakeSession(this.remoteDeviceId, {this.flags = const [], this.answer});

  @override
  final String remoteDeviceId;
  final List<String> flags;
  FutureOr<GeneratedMessage> Function(GeneratedMessage request)? answer;
  final List<GeneratedMessage> sent = [];
  final List<GeneratedMessage> requests = [];

  @override
  bool get isClosed => false;

  @override
  bool supports(String featureId) => featureId == WakeFeature.featureId;

  @override
  FeatureSupport? remoteFeature(String featureId) =>
      FeatureSupport(id: featureId, flags: flags);

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

/// Just enough of the engine for the feature.
class FakeHost implements FeatureHost {
  FakeHost(this.identity, this.trustStore, {Map<String, Object?>? settings})
    : settings = MemorySettingsStore(settings);

  static Future<FakeHost> create({Map<String, Object?>? settings}) async =>
      FakeHost(
        await DeviceIdentity.generate(),
        TrustStore.memory(),
        settings: settings,
      );

  @override
  final DeviceIdentity identity;

  @override
  final TrustStore trustStore;

  @override
  final MemorySettingsStore settings;

  final StreamController<List<Session>> sessionEvents = .broadcast();

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
  Stream<List<Session>> get sessionChanges => sessionEvents.stream;

  /// [session] connects.
  void connect(FakeSession session) {
    sessions = [...sessions, session];
    sessionEvents.add(sessions);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A wired card that wakes, on 192.168.1.0/24.
WakeInfo wiredWake({List<int> mac = const [0x3c, 0x22, 0xfb, 1, 2, 3]}) =>
    WakeInfo(
      interfaces: [
        WakeInterface(
          mac: mac,
          address: '192.168.1.20',
          broadcast: '192.168.1.255',
          link: .WAKE_LINK_WIRED,
          setting: .WAKE_SETTING_ON,
        ),
      ],
    );

/// Pairs [deviceId] in [store] as a computer, with [wake] when given.
Future<void> pairComputer(
  TrustStore store,
  String deviceId, {
  WakeInfo? wake,
  String? lastHost,
}) async {
  await store.save(
    TrustedDevice(
      id: deviceId,
      name: deviceId,
      platform: .PLATFORM_WINDOWS,
      formFactor: .FORM_FACTOR_DESKTOP,
      publicKey: Uint8List(32),
      pairedAt: DateTime(2026, 11),
      lastHost: lastHost,
      wake: wake,
    ),
  );
}

/// [message] as it arrives in an envelope from another device.
Envelope envelopeOf(GeneratedMessage message) => Envelope(
  id: Int64(1),
  feature: WakeFeature.featureId,
  type: message.payloadType,
  payload: message.toPayload(),
  expectsReply: true,
);

/// Lets queued stream events and futures run.
Future<void> settle() async {
  for (var turn = 0; turn < 5; turn++) {
    await Future<void>.delayed(Duration.zero);
  }
}
