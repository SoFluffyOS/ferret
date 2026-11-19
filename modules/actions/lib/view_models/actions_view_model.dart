import 'dart:async';

import 'package:actions/feature/feature.dart';
import 'package:actions/models/models.dart';
import 'package:actions/services/services.dart';
import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:protocol/actions.dart';
import 'package:protocol/protocol.dart' show Platform;

/// What the actions UI shows on both sides: on a computer, who asks, the
/// countdown, the owner's own actions and what ran; on the asking device,
/// what each computer offers and how the last requests went.
class ActionsViewModel extends ChangeNotifier {
  ActionsViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => notifyListeners());
  }

  final ActionsFeature feature;
  late final StreamSubscription<void> _subscription;

  ActionsHost? get _host => feature.actionsHost;

  LeaveLock? get _leaveLock => feature.leaveLock;

  /// Whether this device runs actions for others: computers.
  bool get offersActions => _host != null;

  bool get enabled => _host?.enabled ?? false;

  ActionAsk? get pending => _host?.pending;

  ActionCountdown? get countdown => _host?.countdown;

  List<CustomAction> get custom => _host?.custom ?? const [];

  List<ActionRecord> get recent => _host?.recent ?? const [];

  List<ActionRecord> get history => _host?.history ?? const [];

  List<OutgoingAction> get outgoing => feature.client?.outgoing ?? const [];

  /// How long a custom action may run, in whole seconds.
  int get commandSeconds => feature.commandTimeout.inSeconds;

  /// Whether something needs the owner right now: a device asking, or a
  /// restart or shut down counting down.
  bool get needsOwner => pending != null || countdown != null;

  /// Whether this computer can lock itself when a phone leaves.
  bool get canLockWhenGone => _leaveLock != null;

  /// A phone left and this computer is about to lock, or null.
  LeaveCountdown? get leaveCountdown => _leaveLock?.countdown;

  List<LeaveLockRecord> get leaveRecords => _leaveLock?.recent ?? const [];

  /// Paired phones that can lock this computer when they leave, as id and
  /// name.
  List<({String id, String name})> get watchablePhones {
    if (!canLockWhenGone) {
      return const [];
    }

    final host = feature.host;
    return [
      for (final device in host.trustStore.devices)
        if (LeaveLock.canWatch(device.platform))
          (id: device.id, name: host.displayNameOf(device.id)),
    ];
  }

  bool canWatch(Platform platform) =>
      canLockWhenGone && LeaveLock.canWatch(platform);

  bool locksWhenGone(String deviceId) =>
      feature.settings.locksWhenGone(deviceId);

  int get lockAfterMinutes => feature.settings.lockAfterMinutes;

  Future<void> setLocksWhenGone(String deviceId, {required bool locks}) =>
      feature.settings.setLocksWhenGone(deviceId, locks: locks);

  Future<void> setLockAfterMinutes(int minutes) =>
      feature.settings.setLockAfterMinutes(minutes);

  void cancelLeaveLock() => _leaveLock?.cancel();

  void dismissLeaveRecord(String id) => _leaveLock?.dismissRecord(id);

  List<Action> actionsOf(String deviceId) => feature.actionsOf(deviceId);

  bool isWaiting(String deviceId, String actionId) =>
      feature.client?.isWaiting(deviceId, actionId) ?? false;

  Future<void> run(String deviceId, Action action) async {
    final outgoing = await feature.run(deviceId, action);
    // A volume step that worked needs no line: the sound says so.
    final isQuiet = switch (action.kind) {
      .ACTION_KIND_MUTE ||
      .ACTION_KIND_VOLUME_UP ||
      .ACTION_KIND_VOLUME_DOWN => true,
      _ => false,
    };
    if (outgoing == null || !isQuiet || outgoing.result != .RUN_RESULT_DONE) {
      return;
    }

    feature.client?.dismiss(outgoing.id);
  }

  void dismissOutgoing(String outgoingId) =>
      feature.client?.dismiss(outgoingId);

  Future<void> answer(ActionChoice choice) async => _host?.answer(choice);

  void cancelCountdown() => _host?.cancelCountdown();

  Future<void> setEnabled(bool value) async => _host?.setEnabled(value);

  Future<void> saveCustom({
    required String? id,
    required String name,
    required String commandLine,
  }) async {
    if (id == null) {
      await _host?.addCustom(name: name, commandLine: commandLine);
      return;
    }

    await _host?.updateCustom(id, name: name, commandLine: commandLine);
  }

  Future<void> removeCustom(String id) async => _host?.removeCustom(id);

  void dismissRecord(String id) => _host?.dismissRecord(id);

  Future<void> clearHistory() async => _host?.clearHistory();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
