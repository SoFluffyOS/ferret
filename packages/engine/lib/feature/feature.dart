import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/identity/identity.dart';
import 'package:engine/session/session.dart';
import 'package:engine/trust/trust.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// What a [Feature] can reach in the engine.
abstract interface class FeatureHost {
  DeviceIdentity get identity;

  DeviceInfo get localDevice;

  SettingsStore get settings;

  TrustStore get trustStore;

  /// Open sessions with a finished `Hello`, one per connected device.
  List<Session> get sessions;

  Session? sessionFor(String deviceId);

  /// Fires when a session opens or closes.
  Stream<List<Session>> get sessionChanges;

  /// Sends [message] to every connected device that offers [featureId].
  Future<void> broadcast(String featureId, GeneratedMessage message);

  /// Whether someone is using this device right now, as the app last
  /// reported it. Other devices see it as `Session.remotePresence`.
  Presence get localPresence;

  Stream<Presence> get localPresenceChanges;
}

/// One capability of Ferret, such as handoff or clipboard sync. Features own
/// their messages (`proto/ferret/<id>/v1`) and never talk to each other.
abstract class Feature {
  /// Unique id, also the envelope `feature` field, such as `"clipboard"`.
  String get id;

  int get version => 1;

  /// What this device can do for the feature, such as `send` and `receive`.
  List<String> get flags => const [];

  /// Whether the feature is offered at all on this device right now, such as
  /// when the user turned it off or the platform can't do it.
  bool get isAvailable => true;

  late FeatureHost _host;

  FeatureHost get host => _host;

  FeatureSupport get support =>
      FeatureSupport(id: id, version: version, flags: flags);

  /// Called once, before any session opens.
  Future<void> start(FeatureHost host) async {
    _host = host;
    await onStart();
  }

  Future<void> onStart() async {}

  Future<void> stop() async {}

  void onSessionOpened(Session session) {}

  void onSessionClosed(Session session) {}

  /// Handles an envelope for this feature. Return a message to answer a
  /// request with it; return null to answer nothing (or reply yourself).
  Future<GeneratedMessage?> onEnvelope(Session session, Envelope envelope);
}

/// Decodes [envelope]'s payload as [T] when its type matches.
T? payloadOf<T extends GeneratedMessage>(
  Envelope envelope,
  T Function() create,
) => unpackPayload(
  type: envelope.type,
  payload: envelope.payload,
  create: create,
);
