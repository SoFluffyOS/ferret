import 'dart:async';

import 'package:actions/models/models.dart';
import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:protocol/actions.dart';

/// The asking side: what each connected computer offers, and how the
/// actions this device asked for went.
class ActionsClient {
  ActionsClient({
    required FeatureHost host,
    required this.featureId,
    required this.replyTimeout,
    DateTime Function()? clock,
  }) : _host = host,
       _clock = clock ?? DateTime.now;

  final String featureId;

  /// How long to wait for a computer's answer: it may ask its owner, count
  /// down, and run a command first.
  final Duration replyTimeout;

  final FeatureHost _host;
  final DateTime Function() _clock;
  final Map<String, List<Action>> _lists = {};
  final Map<String, OutgoingAction> _outgoing = {};
  final StreamController<void> _changes = .broadcast();

  Stream<void> get changes => _changes.stream;

  /// What [deviceId] offers right now, or empty.
  List<Action> actionsOf(String deviceId) =>
      List.unmodifiable(_lists[deviceId] ?? const []);

  /// What this device asked for, the last per computer and action, newest
  /// first.
  List<OutgoingAction> get outgoing =>
      [..._outgoing.values]
        ..sort((first, second) => second.at.compareTo(first.at));

  bool isWaiting(String deviceId, String actionId) => _outgoing.values.any(
    (outgoing) =>
        outgoing.deviceId == deviceId &&
        outgoing.action.id == actionId &&
        outgoing.isWaiting,
  );

  void onList(Session session, ActionList list) {
    _lists[session.remoteDeviceId] = [...list.actions];
    _emit();
  }

  void onSessionClosed(String deviceId) {
    if (_lists.remove(deviceId) == null) {
      return;
    }

    _emit();
  }

  /// Asks [deviceId] to run [action] and waits for how it went.
  Future<OutgoingAction> run(String deviceId, Action action) async {
    final deviceName = _host.displayNameOf(deviceId);
    final asked = OutgoingAction(
      deviceId: deviceId,
      deviceName: deviceName,
      action: action,
      at: _clock(),
    );
    _outgoing[asked.id] = asked;
    _emit();

    final reply = await _ask(deviceId, action);
    final answered = OutgoingAction(
      deviceId: deviceId,
      deviceName: deviceName,
      action: action,
      at: _clock(),
      result: reply.result,
      exitCode: switch (reply.hasExitCode()) {
        true => reply.exitCode,
        false => null,
      },
    );
    _outgoing[answered.id] = answered;
    _emit();

    return answered;
  }

  void dismiss(String outgoingId) {
    if (_outgoing.remove(outgoingId) == null) {
      return;
    }

    _emit();
  }

  Future<void> dispose() => _changes.close();

  Future<RunActionReply> _ask(String deviceId, Action action) async {
    final session = _host.sessionFor(deviceId);
    if (session == null) {
      return RunActionReply(result: .RUN_RESULT_FAILED);
    }

    try {
      final reply = await session.request(
        featureId,
        RunAction(id: action.id),
        timeout: replyTimeout,
      );
      return payloadOf(reply, RunActionReply.new) ??
          RunActionReply(result: .RUN_RESULT_FAILED);
    } on Object catch (error) {
      printWarning('Running an action on $deviceId failed', error);
      return RunActionReply(result: _unansweredResult(deviceId, action));
    }
  }

  /// A computer that went to sleep or off may be gone before its answer
  /// is: gone without a word then means it worked.
  RunResult _unansweredResult(String deviceId, Action action) {
    final leaves = switch (action.kind) {
      .ACTION_KIND_SLEEP ||
      .ACTION_KIND_RESTART ||
      .ACTION_KIND_SHUT_DOWN => true,
      _ => false,
    };
    if (leaves && _host.sessionFor(deviceId) == null) {
      return .RUN_RESULT_DONE;
    }

    return .RUN_RESULT_NOT_ANSWERED;
  }

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
