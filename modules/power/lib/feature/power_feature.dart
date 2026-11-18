import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// The engine side of Power-ups.
class PowerFeature extends Feature {
  static const featureId = 'power';

  @override
  String get id => featureId;

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async => null;
}
