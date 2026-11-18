import 'dart:async';
import 'dart:io' as io;

import 'package:engine/engine.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/services/services.dart';

/// Use a phone as the touchpad and keyboard of a computer. The computer
/// asks its owner the first time per device, shows that it is being
/// controlled with a Stop, and keeps an audit line of each time.
class RemoteInputFeature extends Feature {
  RemoteInputFeature({
    InputInjector Function()? injector,
    bool? canBeControlled,
    bool? canControl,
    DateTime Function()? clock,
    this.consentTimeout = const Duration(seconds: 60),
    this.idleTimeout = const Duration(minutes: 10),
    this.requestTimeout = const Duration(seconds: 10),
  }) : _createInjector = injector ?? InputInjector.current,
       canBeControlled = canBeControlled ?? InputInjector.isSupportedPlatform,
       canControl = canControl ?? (io.Platform.isAndroid || io.Platform.isIOS),
       _clock = clock ?? DateTime.now;

  static const featureId = 'remote_input';

  /// Flag in [FeatureSupport]: this device can be controlled.
  static const controlFlag = 'control';

  /// Flag in [FeatureSupport]: this device can act as a touchpad.
  static const controllerFlag = 'controller';

  /// This device injects input for others: computers.
  final bool canBeControlled;

  /// This device offers itself as a touchpad: phones and tablets.
  final bool canControl;

  final Duration consentTimeout;
  final Duration idleTimeout;
  final Duration requestTimeout;

  final InputInjector Function() _createInjector;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final List<StreamSubscription<void>> _subscriptions = [];

  ControlHost? _controlHost;
  ControlClient? _client;

  @override
  String get id => featureId;

  @override
  List<String> get flags => [
    if (canBeControlled) controlFlag,
    if (canControl) controllerFlag,
  ];

  RemoteInputSettings get settings => RemoteInputSettings(host.settings);

  /// This computer's side, or null on phones.
  ControlHost? get controlHost => _controlHost;

  /// The touchpad side, or null on computers.
  ControlClient? get client => _client;

  /// Fires when anything the UI shows may have changed.
  Stream<void> get changes => _changes.stream;

  /// Whether [session]'s device can be controlled from here.
  bool canControlDevice(Session session) =>
      canControl &&
      (session.remoteFeature(featureId)?.flags.contains(controlFlag) ?? false);

  @override
  Future<void> onStart() async {
    if (canBeControlled) {
      final controlHost = ControlHost(
        host: host,
        featureId: featureId,
        injector: _createInjector(),
        settings: settings,
        clock: _clock,
        consentTimeout: consentTimeout,
        idleTimeout: idleTimeout,
      );
      _controlHost = controlHost;
      _subscriptions.add(controlHost.changes.listen((_) => _emit()));
      await controlHost.start();
    }

    if (canControl) {
      final client = ControlClient(
        host: host,
        featureId: featureId,
        requestTimeout: requestTimeout,
        clock: _clock,
      );
      _client = client;
      _subscriptions.add(client.changes.listen((_) => _emit()));
    }

    _subscriptions.add(settings.changes.listen((_) => _emit()));
  }

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _controlHost?.dispose();
    await _client?.dispose();
  }

  @override
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    unawaited(_controlHost?.onSessionClosed(deviceId));
    _client?.onSessionClosed(deviceId);
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, InputBatch.new) case final batch?) {
      await _controlHost?.onBatch(session, batch);
      return null;
    }

    if (payloadOf(envelope, ControlRequest.new) case final request?) {
      final controlHost = _controlHost;
      if (controlHost == null) {
        return ControlDeny(reason: .DENY_REASON_UNSUPPORTED);
      }

      return controlHost.onRequest(session, request);
    }

    if (payloadOf(envelope, ControlStop.new) case final stop?) {
      await _controlHost?.onStop(session);
      _client?.onStop(session, stop);
      return null;
    }

    if (payloadOf(envelope, ControlGrant.new) case final grant?) {
      _client?.onGrant(session, grant);
      return null;
    }

    if (payloadOf(envelope, ControlDeny.new) case final deny?) {
      _client?.onDeny(session, deny);
    }

    return null;
  }

  /// Asks [deviceId] for control; the touchpad page follows [client].
  Future<OutgoingControl?> control(String deviceId) async =>
      _client?.start(deviceId);

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
