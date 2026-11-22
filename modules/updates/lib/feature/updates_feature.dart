import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:updates/models/models.dart';

/// Updates live on this device only: nothing is said to other devices, so
/// the feature is never offered to them. It holds the settings.
class UpdatesFeature extends Feature {
  static const featureId = 'updates';

  @override
  String get id => featureId;

  @override
  bool get isAvailable => false;

  UpdateSettings get settings => UpdateSettings(host.settings);

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async => null;
}
