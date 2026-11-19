import 'dart:async';

import 'package:actions/models/models.dart';
import 'package:actions/services/services.dart';
import 'package:engine/engine.dart';
import 'package:ferret_actions/ferret_actions.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/actions.dart';
import 'package:protocol/protocol.dart';

/// Run a computer's actions from another device: sleep, restart, shut
/// down, sound, and commands its owner defined there. The computer asks
/// its owner the first time per device and action, counts down before it
/// restarts or shuts down, and keeps a line of each time. Only action ids
/// travel, never a command line. A computer also locks itself when a
/// phone its owner chose leaves ([LeaveLock]).
class ActionsFeature extends Feature {
  ActionsFeature({
    ComputerActions? computer,
    CommandRunner? runner,
    ScreenLocker? locker,
    InputIdle? idle,
    bool? offersActions,
    DateTime Function()? clock,
    this.consentTimeout = const Duration(seconds: 60),
    this.countdownLength = const Duration(seconds: 10),
    this.commandTimeout = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 10),
    this.leaveDelay = const Duration(milliseconds: 500),
    this.idleBeforeLock = const Duration(minutes: 1),
    this.lockMinute = const Duration(minutes: 1),
  }) : _computer = computer ?? ComputerActions.current(),
       _runner = runner ?? CommandRunner(),
       _locker = locker ?? ScreenLocker.current(),
       _idle = idle ?? InputIdle.current(),
       _offersActions = offersActions,
       _clock = clock ?? DateTime.now;

  static const featureId = 'actions';

  /// Flag in [FeatureSupport]: this computer runs actions for others.
  static const runFlag = 'run';

  final Duration consentTimeout;
  final Duration countdownLength;
  final Duration commandTimeout;
  final Duration requestTimeout;
  final Duration leaveDelay;

  /// How long nobody may have touched this computer before a phone that
  /// left locks it.
  final Duration idleBeforeLock;

  /// How long one minute of "Lock after" lasts. Renders shorten it.
  final Duration lockMinute;

  final ComputerActions _computer;
  final CommandRunner _runner;
  final ScreenLocker _locker;
  final InputIdle _idle;
  final bool? _offersActions;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final List<StreamSubscription<void>> _subscriptions = [];

  ActionsHost? _actionsHost;
  LeaveLock? _leaveLock;
  ActionsClient? _client;

  @override
  String get id => featureId;

  @override
  List<String> get flags => [if (offersActions) runFlag];

  /// This device runs actions for others: a computer whose platform can.
  /// False until the feature started.
  bool get offersActions => _actionsHost != null;

  ActionsSettings get settings => ActionsSettings(host.settings);

  /// This computer's side, or null on phones.
  ActionsHost? get actionsHost => _actionsHost;

  /// Locking this computer when a phone leaves, or null on phones and
  /// where the screen can't be locked.
  LeaveLock? get leaveLock => _leaveLock;

  /// The asking side. Null only before the feature started.
  ActionsClient? get client => _client;

  /// Fires when anything the UI shows may have changed.
  Stream<void> get changes => _changes.stream;

  /// How long a device waits for an answer, at most.
  Duration get replyTimeout =>
      consentTimeout + countdownLength + commandTimeout + requestTimeout;

  @override
  Future<void> onStart() async {
    if (_offersActions ?? _isComputer) {
      final actionsHost = ActionsHost(
        host: host,
        featureId: featureId,
        computer: _computer,
        runner: _runner,
        settings: settings,
        clock: _clock,
        consentTimeout: consentTimeout,
        countdownLength: countdownLength,
        commandTimeout: commandTimeout,
        leaveDelay: leaveDelay,
      )..start();
      _actionsHost = actionsHost;
      _subscriptions.add(actionsHost.changes.listen((_) => _emit()));
    }

    if ((_offersActions ?? _isComputer) && _locker.isSupported) {
      final leaveLock = LeaveLock(
        host: host,
        settings: settings,
        locker: _locker,
        idle: _idle,
        clock: _clock,
        idleNeeded: idleBeforeLock,
        countdownLength: countdownLength,
        minute: lockMinute,
      )..start();
      _leaveLock = leaveLock;
      _subscriptions.add(leaveLock.changes.listen((_) => _emit()));
    }

    final client = ActionsClient(
      host: host,
      featureId: featureId,
      replyTimeout: replyTimeout,
      clock: _clock,
    );
    _client = client;
    _subscriptions.add(client.changes.listen((_) => _emit()));
  }

  bool get _isComputer => switch (host.localDevice.platform) {
    .PLATFORM_MACOS ||
    .PLATFORM_WINDOWS ||
    .PLATFORM_LINUX => _computer.supported.isNotEmpty,
    _ => false,
  };

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _actionsHost?.dispose();
    await _leaveLock?.dispose();
    await _client?.dispose();
    await _changes.close();
  }

  @override
  void onSessionOpened(Session session) {
    unawaited(_actionsHost?.sendList(session));
    _leaveLock?.onSessionOpened(session);
  }

  @override
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    _actionsHost?.onSessionClosed(deviceId);
    _client?.onSessionClosed(deviceId);
    _leaveLock?.onSessionClosed(session);
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, ActionList.new) case final list?) {
      _client?.onList(session, list);
      return null;
    }

    if (payloadOf(envelope, RunAction.new) case final request?) {
      final actionsHost = _actionsHost;
      if (actionsHost == null) {
        return RunActionReply(result: .RUN_RESULT_UNKNOWN_ACTION);
      }

      return actionsHost.onRun(session, request);
    }

    return null;
  }

  /// What [deviceId] offers right now, or empty.
  List<Action> actionsOf(String deviceId) =>
      _client?.actionsOf(deviceId) ?? const [];

  /// Asks [deviceId] to run [action]. Its owner may be asked first, so
  /// this can take up to [replyTimeout]. Null before the feature started.
  Future<OutgoingAction?> run(String deviceId, Action action) async =>
      _client?.run(deviceId, action);

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
