import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_wake/ferret_wake.dart';
import 'package:protocol/protocol.dart';

/// Records packets instead of sending them.
class FakeSender implements WakeSender {
  final List<List<WakePacket>> sends = [];

  @override
  Future<List<WakePacket>> send(List<WakePacket> packets) async {
    sends.add(packets);
    return packets;
  }
}

/// Just enough of the engine for the feature, with nobody connected.
class FakeHost implements FeatureHost {
  FakeHost(this.identity, this.trustStore);

  static Future<FakeHost> create() async =>
      FakeHost(await DeviceIdentity.generate(), TrustStore.memory());

  @override
  final DeviceIdentity identity;

  @override
  final TrustStore trustStore;

  @override
  final MemorySettingsStore settings = MemorySettingsStore();

  @override
  List<Session> get sessions => const [];

  @override
  Session? sessionFor(String deviceId) => null;

  @override
  Stream<List<Session>> get sessionChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEngine implements FerretEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A wired card with Wake-on-LAN on.
WakeInfo wiredWake({WakeSetting setting = .WAKE_SETTING_ON}) => WakeInfo(
  interfaces: [
    WakeInterface(
      mac: const [0x3c, 0x22, 0xfb, 1, 2, 3],
      address: '192.168.1.20',
      broadcast: '192.168.1.255',
      link: .WAKE_LINK_WIRED,
      setting: setting,
    ),
  ],
);

TrustedDevice computer({WakeInfo? wake}) => TrustedDevice(
  id: 'mbp',
  name: 'MacBook Pro',
  platform: .PLATFORM_MACOS,
  formFactor: .FORM_FACTOR_LAPTOP,
  publicKey: Uint8List(32),
  pairedAt: DateTime(2026, 11),
  wake: wake,
);
