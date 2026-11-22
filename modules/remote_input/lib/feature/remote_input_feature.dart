import 'dart:async';
import 'dart:io' as io;

import 'package:core/core.dart';
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
    ScreenLocker? locker,
    bool? canBeControlled,
    bool? canControl,
    bool? canSwitchScreens,
    InputCapture Function()? capture,
    Future<String?> Function()? secureInputHolder,
    DateTime Function()? clock,
    this.consentTimeout = const Duration(seconds: 60),
    this.idleTimeout = const Duration(minutes: 10),
    this.requestTimeout = const Duration(seconds: 10),
  }) : _createInjector = injector ?? InputInjector.current,
       _locker = locker ?? ScreenLocker.current(),
       canBeControlled = canBeControlled ?? InputInjector.isSupportedPlatform,
       canControl = canControl ?? (io.Platform.isAndroid || io.Platform.isIOS),
       canSwitchScreens =
           canSwitchScreens ??
           (InputCapture.isSupportedPlatform &&
               (canBeControlled ?? InputInjector.isSupportedPlatform)),
       _createCapture = capture ?? InputCapture.current,
       _secureInputHolder = secureInputHolder ?? SecureInputHolder.find,
       _clock = clock ?? DateTime.now;

  static const featureId = 'remote_input';

  /// Flag in [FeatureSupport]: this device can be controlled.
  static const controlFlag = 'control';

  /// Flag in [FeatureSupport]: this device can act as a touchpad.
  static const controllerFlag = 'controller';

  /// Flag in [FeatureSupport]: this computer locks its screen when asked
  /// with a `LockRequest`.
  static const lockFlag = 'lock';

  /// Flag in [FeatureSupport]: this computer takes another computer's
  /// keyboard and mouse (`CONTROL_MODE_SCREEN`, `EnterScreen`).
  static const screenFlag = ScreenSwitch.screenFlag;

  /// Flag in [FeatureSupport]: this computer can lend its own keyboard and
  /// mouse to others.
  static const screenSenderFlag = 'screen_sender';

  /// How long a phone waits for a lock: the computer may ask its owner
  /// first.
  Duration get lockTimeout => consentTimeout + requestTimeout;

  /// This device injects input for others: computers.
  final bool canBeControlled;

  /// This device offers itself as a touchpad: phones and tablets.
  final bool canControl;

  /// This computer lends its own keyboard and mouse with ⌃⌥→: macOS.
  final bool canSwitchScreens;

  final Duration consentTimeout;
  final Duration idleTimeout;
  final Duration requestTimeout;

  final InputInjector Function() _createInjector;
  final InputCapture Function() _createCapture;
  final Future<String?> Function() _secureInputHolder;
  final ScreenLocker _locker;
  final Map<String, OutgoingLock> _locks = {};
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final List<StreamSubscription<void>> _subscriptions = [];

  ControlHost? _controlHost;
  ControlClient? _client;
  ControlClient? _screenClient;
  ScreenSwitch? _screenSwitch;

  @override
  String get id => featureId;

  @override
  List<String> get flags => [
    if (canBeControlled) controlFlag,
    if (canBeControlled && _locker.isSupported) lockFlag,
    if (canControl) controllerFlag,
    if (canBeControlled) screenFlag,
    if (canSwitchScreens) screenSenderFlag,
  ];

  RemoteInputSettings get settings => RemoteInputSettings(host.settings);

  /// This computer's side, or null on phones.
  ControlHost? get controlHost => _controlHost;

  /// The touchpad side, or null on computers.
  ControlClient? get client => _client;

  /// This Mac's keyboard and mouse on other computers, or null where it
  /// can't lend them.
  ScreenSwitch? get screenSwitch => _screenSwitch;

  /// Fires when anything the UI shows may have changed.
  Stream<void> get changes => _changes.stream;

  /// The last lock this phone asked of each computer, newest first.
  List<OutgoingLock> get locks =>
      [..._locks.values]
        ..sort((first, second) => second.at.compareTo(first.at));

  /// Whether [session]'s device can be locked from here.
  bool canLockDevice(Session session) =>
      canControl &&
      (session.remoteFeature(featureId)?.flags.contains(lockFlag) ?? false);

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
        locker: _locker,
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

    if (canSwitchScreens) {
      final screenClient = ControlClient(
        host: host,
        featureId: featureId,
        mode: .CONTROL_MODE_SCREEN,
        requestTimeout: requestTimeout,
        batchInterval: screenBatchInterval,
        clock: _clock,
      );
      final screenSwitch = ScreenSwitch(
        host: host,
        featureId: featureId,
        client: screenClient,
        settings: settings,
        capture: _createCapture,
        secureInputHolder: _secureInputHolder,
        clock: _clock,
      );
      _screenClient = screenClient;
      _screenSwitch = screenSwitch;
      _subscriptions.add(screenSwitch.changes.listen((_) => _emit()));
      await screenSwitch.start();
    }

    _subscriptions.add(settings.changes.listen((_) => _emit()));
  }

  /// A mouse moves more often than a finger: batches leave at up to 120 a
  /// second.
  static const screenBatchInterval = Duration(milliseconds: 8);

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _screenSwitch?.dispose();
    await _screenClient?.dispose();
    await _controlHost?.dispose();
    await _client?.dispose();
  }

  @override
  Future<void> onPairedDevices(Set<String> deviceIds) =>
      host.settings.keepOnlyPaired([
        RemoteInputSettings.allowedDevicesKey,
        RemoteInputSettings.lockDevicesKey,
      ], deviceIds);
  @override
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    unawaited(_controlHost?.onSessionClosed(deviceId));
    _client?.onSessionClosed(deviceId);
    _screenClient?.onSessionClosed(deviceId);
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

    if (payloadOf(envelope, LockRequest.new) != null) {
      final controlHost = _controlHost;
      if (controlHost == null) {
        return LockReply(result: .LOCK_RESULT_FAILED);
      }

      return controlHost.onLockRequest(session);
    }

    if (payloadOf(envelope, ControlRequest.new) case final request?) {
      final controlHost = _controlHost;
      if (controlHost == null) {
        return ControlDeny(reason: .DENY_REASON_UNSUPPORTED);
      }

      return controlHost.onRequest(session, request);
    }

    if (payloadOf(envelope, ControlStop.new) case final stop?) {
      await _onStop(session, stop);
      return null;
    }

    if (payloadOf(envelope, ControlGrant.new) case final grant?) {
      _client?.onGrant(session, grant);
      _screenClient?.onGrant(session, grant);
      return null;
    }

    if (payloadOf(envelope, ControlDeny.new) case final deny?) {
      _client?.onDeny(session, deny);
      _screenClient?.onDeny(session, deny);
    }

    return null;
  }

  /// Two computers can control each other, so a stop goes to the side it
  /// is meant for: a controller only ever says it is done, everything else
  /// comes from a computer that was controlled.
  Future<void> _onStop(Session session, ControlStop stop) async {
    switch (stop.reason) {
      case .STOP_REASON_CONTROLLER_DONE || .STOP_REASON_UNSPECIFIED:
        await _controlHost?.onStop(session);
      default:
        _client?.onStop(session, stop);
        _screenClient?.onStop(session, stop);
    }
  }

  /// Asks [deviceId] for control; the touchpad page follows [client].
  Future<OutgoingControl?> control(String deviceId) async =>
      _client?.start(deviceId);

  /// Asks [deviceId] to lock its screen. Its owner may be asked first, so
  /// this can take up to [lockTimeout].
  Future<LockResult> lockDevice(String deviceId) async {
    final deviceName = host.displayNameOf(deviceId);
    _locks[deviceId] = OutgoingLock(
      deviceId: deviceId,
      deviceName: deviceName,
      at: _clock(),
    );
    _emit();

    final result = await _askToLock(deviceId);
    _locks[deviceId] = OutgoingLock(
      deviceId: deviceId,
      deviceName: deviceName,
      at: _clock(),
      result: result,
    );
    _emit();
    return result;
  }

  void dismissLock(String deviceId) {
    _locks.remove(deviceId);
    _emit();
  }

  Future<LockResult> _askToLock(String deviceId) async {
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return .LOCK_RESULT_FAILED;
    }

    try {
      final reply = await session.request(
        featureId,
        LockRequest(),
        timeout: lockTimeout,
      );
      return payloadOf(reply, LockReply.new)?.result ?? .LOCK_RESULT_FAILED;
    } on Object catch (error) {
      printWarning('Locking $deviceId failed', error);
      return .LOCK_RESULT_TIMEOUT;
    }
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
