import 'dart:async';

import 'package:calls/models/models.dart';
import 'package:calls/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:protocol/calls.dart';

/// The dialer for one phone: its recent calls, and starting a call.
class DialerViewModel extends ChangeNotifier {
  DialerViewModel({
    required CallsControl control,
    required this.deviceId,
    required this.deviceName,
  }) : _control = control {
    unawaited(loadRecent());
  }

  final CallsControl _control;
  final String deviceId;
  final String deviceName;

  List<CallLogEntry> _entries = const [];
  CallLogProblem? _logProblem;
  CommandOutcome? _outcome;
  bool _loading = false;
  bool _calling = false;
  bool _disposed = false;

  /// Newest first.
  List<CallLogEntry> get entries => _entries;

  bool get loading => _loading;

  /// Why the recent calls are missing, if they are.
  CallLogProblem? get logProblem => _logProblem;

  /// A call request is on its way to the phone.
  bool get calling => _calling;

  /// How the last call request ended, null before the first one.
  CommandOutcome? get outcome => _outcome;

  Future<void> loadRecent() async {
    if (_loading) {
      return;
    }

    _loading = true;
    _notify();

    final result = await _control.fetchCallLog(deviceId);
    _entries = result.entries;
    _logProblem = result.problem;
    _loading = false;
    _notify();
  }

  /// Asks the phone to call [number].
  Future<void> call(String number) async {
    if (_calling) {
      return;
    }

    if (PhoneNumbers.dialable(number) == null) {
      _outcome = .invalidNumber;
      _notify();
      return;
    }

    _calling = true;
    _outcome = null;
    _notify();

    _outcome = await _control.dial(deviceId, number);
    _calling = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
