import 'dart:async';

import 'package:calls/feature/calls_feature.dart';
import 'package:ferret_calls/ferret_calls.dart';
import 'package:flutter/foundation.dart';

/// Where the phone is in turning calls on.
enum CallsSetupStage {
  /// Calls are off: explain them first.
  off,

  /// Calls are on but Android doesn't let Ferret see them yet.
  needsPermission,

  /// Computers see this phone's calls.
  ready,
}

/// Turns calls on for this phone: the explainer, Android's permission
/// dialogs, the app settings page when Android won't ask again, and a
/// re-check when the person comes back.
class PhoneSetupViewModel extends ChangeNotifier {
  PhoneSetupViewModel(this._feature) {
    _subscription = _feature.changes.listen((_) => _notify());
    unawaited(refresh());
  }

  final CallsFeature _feature;
  late final StreamSubscription<void> _subscription;

  bool _asked = false;
  bool _openFailed = false;
  bool _busy = false;
  bool _disposed = false;

  PlatformCallPermissions? get _permissions => _feature.permissions;

  CallsSetupStage get stage {
    if (!_feature.settings.enabled) {
      return .off;
    }

    if (!canSeeCalls) {
      return .needsPermission;
    }

    return .ready;
  }

  /// The permissions were read at least once.
  bool get checked => _permissions != null;

  bool get canSeeCalls => _permissions?.phoneState ?? false;

  bool get canSeeNumbers => _permissions?.callLog ?? false;

  bool get canSeeContacts => _permissions?.contacts ?? false;

  bool get canAnswer => _permissions?.answerCalls ?? false;

  bool get canDial => _permissions?.placeCalls ?? false;

  /// Something a computer could do is still not allowed.
  bool get hasMissing =>
      !(canSeeCalls && canSeeNumbers && canSeeContacts && canAnswer && canDial);

  /// Android will no longer show its dialog, so only the app's settings
  /// page can allow what is missing.
  bool get needsSettings => !(_permissions?.canAskAgain ?? true);

  /// The person was asked and what Ferret needs is still off.
  bool get stillOff => _asked && !canSeeCalls;

  /// The app's settings page could not be opened.
  bool get openFailed => _openFailed;

  /// Re-reads the permissions, such as when the app comes back to the front.
  Future<void> refresh() async {
    await _feature.refreshPermissions();
    _notify();
  }

  /// The explainer's button: turns calls on and asks for the permissions.
  Future<void> turnOn() async {
    await _feature.settings.setEnabled(true);
    await allow();
  }

  /// Asks for what is missing: Android's dialogs, or the app's settings
  /// page once Android won't ask again.
  Future<void> allow() async {
    if (_busy) {
      return;
    }

    if (needsSettings) {
      await openSettings();
      return;
    }

    _busy = true;
    try {
      await _feature.requestPermissions();
    } finally {
      _busy = false;
    }

    _asked = true;
    _notify();
  }

  Future<void> openSettings() async {
    _openFailed = !await _feature.openAppSettings();
    _notify();
  }

  Future<void> turnOff() => _feature.settings.setEnabled(false);

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
