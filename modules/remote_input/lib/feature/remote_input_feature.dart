import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// The engine side of Remote input.
class RemoteInputFeature extends Feature {
  static const featureId = 'remote_input';

  @override
  String get id => featureId;

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async => null;
}
