import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// The engine side of Screen mirroring.
class MirroringFeature extends Feature {
  static const featureId = 'mirroring';

  @override
  String get id => featureId;

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async => null;
}
