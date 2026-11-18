import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/services.dart';

/// Where the phone is in turning Messages on.
enum SetupStage {
  /// The device has no SMS.
  unsupported,

  /// Messages are off: explain first.
  off,

  /// On, but Android doesn't let Ferret read SMS yet.
  needsAccess,

  /// Everything works.
  ready,
}

/// Turns Messages on for this phone: explainer, the permission dialog, the
/// app settings page when Android won't ask again, and a re-check when the
/// person comes back to Ferret.
class PhoneSetupViewModel extends ChangeNotifier {
  PhoneSetupViewModel(this._service) {
    _subscription = _service.changes.listen((_) => _notify());
    unawaited(refresh());
  }

  final SourceService _service;
  late final StreamSubscription<void> _subscription;

  bool _waitingForReturn = false;
  bool _stillOff = false;
  bool _openFailed = false;
  bool _asking = false;
  bool _disposed = false;

  SmsAccess get access => _service.access;

  SetupStage get stage {
    if (!access.hasTelephony) {
      return .unsupported;
    }

    if (!_service.settings.enabled) {
      return .off;
    }

    if (!access.canRead) {
      return .needsAccess;
    }

    return .ready;
  }

  /// Came back from Settings or the dialog and SMS is still off.
  bool get stillOff => _stillOff;

  /// Android won't show the dialog again; only Settings can grant it.
  bool get blocked => access.blocked;

  bool get openFailed => _openFailed;

  bool get asking => _asking;

  bool get contactsMissing => !access.canReadContacts;

  bool get sendMissing => !access.canSend;

  Future<void> refresh() async {
    await _service.refreshAccess();
    _notify();
  }

  /// The explainer's button: turns Messages on and asks for access.
  Future<void> turnOn() async {
    await _service.settings.setEnabled(true);
    await refresh();
    if (!access.canRead || !access.canReadContacts) {
      await requestAccess();
    }
  }

  Future<void> turnOff() => _service.settings.setEnabled(false);

  /// Shows Android's dialog, or opens Settings when Android won't ask again.
  Future<void> requestAccess() async {
    if (blocked) {
      await openAppSettings();
      return;
    }

    _asking = true;
    _openFailed = false;
    _notify();

    final granted = await _service.requestAccess();
    _asking = false;
    _stillOff = !granted.canRead;
    _notify();
  }

  Future<void> openAppSettings() async {
    _openFailed = false;
    _stillOff = false;
    final opened = await _service.openAppSettings();
    _waitingForReturn = opened;
    _openFailed = !opened;
    _notify();
  }

  /// Call when the app comes back to the front.
  Future<void> onResumed() async {
    if (!_waitingForReturn && stage != .needsAccess) {
      return;
    }

    final wasWaiting = _waitingForReturn;
    _waitingForReturn = false;
    await refresh();
    if (wasWaiting) {
      _stillOff = !access.canRead;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
