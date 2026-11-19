import 'package:core/core.dart';
import 'package:engine/access/device_access.dart';
import 'package:engine/feature/feature.dart';
import 'package:engine/identity/identity.dart';
import 'package:engine/session/session.dart';
import 'package:engine/trust/trust.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// What one feature sees of the engine: only the devices that may use it.
/// A device the person turned the feature off for is simply not connected,
/// as far as the feature can tell.
class ScopedFeatureHost implements FeatureHost {
  ScopedFeatureHost(this._host, this._access, this._featureId);

  final FeatureHost _host;
  final DeviceAccess _access;
  final String _featureId;

  bool _allows(Session session) =>
      !_access.isBlocked(session.remoteDeviceId, _featureId);

  @override
  DeviceIdentity get identity => _host.identity;

  @override
  DeviceInfo get localDevice => _host.localDevice;

  @override
  SettingsStore get settings => _host.settings;

  @override
  TrustStore get trustStore => _host.trustStore;

  @override
  List<Session> get sessions => [
    for (final session in _host.sessions)
      if (_allows(session)) session,
  ];

  @override
  Session? sessionFor(String deviceId) => switch (_host.sessionFor(deviceId)) {
    final session? when _allows(session) => session,
    _ => null,
  };

  @override
  Stream<List<Session>> get sessionChanges => _host.sessionChanges.map(
    (sessions) => [
      for (final session in sessions)
        if (_allows(session)) session,
    ],
  );

  @override
  Future<void> broadcast(String featureId, GeneratedMessage message) async {
    for (final session in sessions) {
      if (!session.supports(featureId)) {
        continue;
      }

      try {
        await session.send(featureId, message);
      } on Object catch (error) {
        printWarning(
          'Broadcast of $featureId to ${session.remoteDeviceId} failed',
          error,
        );
      }
    }
  }

  @override
  Presence get localPresence => _host.localPresence;

  @override
  Stream<Presence> get localPresenceChanges => _host.localPresenceChanges;
}
