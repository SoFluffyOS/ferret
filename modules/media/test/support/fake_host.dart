import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// A host with settings and no connected devices, for UI tests.
class FakeHost implements FeatureHost {
  @override
  final SettingsStore settings = MemorySettingsStore();

  @override
  List<Session> get sessions => const [];

  @override
  Session? sessionFor(String deviceId) => null;

  @override
  Stream<List<Session>> get sessionChanges => const Stream.empty();

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {}

  @override
  DeviceIdentity get identity => throw UnimplementedError();

  @override
  DeviceInfo get localDevice => DeviceInfo(name: 'Test');

  @override
  TrustStore get trustStore => throw UnimplementedError();
}
