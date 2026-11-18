import 'dart:async';

import 'package:calls/models/models.dart';
import 'package:calls/services/services.dart';
import 'package:flutter/foundation.dart';

/// The calls ringing or going on, on connected phones, and what the home
/// card can do with them.
class ActiveCallsViewModel extends ChangeNotifier {
  ActiveCallsViewModel(this._control) {
    _subscription = _control.changes.listen((_) => _onChanged());
  }

  final CallsControl _control;
  late final StreamSubscription<void> _subscription;
  final Set<String> _busy = {};
  final Set<String> _silenced = {};
  final Map<String, CommandOutcome> _problems = {};
  bool _disposed = false;

  /// Ringing calls first, then the oldest first.
  List<RemoteCall> get calls =>
      [..._control.remoteCalls]..sort((first, second) {
        if (first.isRinging != second.isRinging) {
          return switch (first.isRinging) {
            true => -1,
            false => 1,
          };
        }

        return first.startedAt.compareTo(second.startedAt);
      });

  /// A command for [call] is on its way to the phone.
  bool isBusy(RemoteCall call) => _busy.contains(call.key);

  bool isSilenced(RemoteCall call) => _silenced.contains(call.key);

  /// Why the last command for [call] did not work, if it didn't.
  CommandOutcome? problemOf(RemoteCall call) => _problems[call.key];

  Future<void> answer(RemoteCall call) => _run(call, _control.answer);

  /// Declines [call] while it rings, hangs it up otherwise.
  Future<void> end(RemoteCall call) => _run(call, _control.end);

  Future<void> silence(RemoteCall call) async {
    final outcome = await _run(call, _control.silence);
    if (outcome == .ok) {
      _silenced.add(call.key);
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  Future<CommandOutcome?> _run(
    RemoteCall call,
    Future<CommandOutcome> Function(RemoteCall call) command,
  ) async {
    if (_busy.contains(call.key)) {
      return null;
    }

    _busy.add(call.key);
    _problems.remove(call.key);
    _notify();

    final outcome = await command(call);
    _busy.remove(call.key);
    if (!outcome.isOk) {
      _problems[call.key] = outcome;
    }

    _forgetEndedCalls();
    _notify();
    return outcome;
  }

  void _onChanged() {
    _forgetEndedCalls();
    _notify();
  }

  void _forgetEndedCalls() {
    final live = {for (final call in _control.remoteCalls) call.key};
    _silenced.retainAll(live);
    _problems.removeWhere((key, _) => !live.contains(key));
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
