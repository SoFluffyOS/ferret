import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:ferret_find/ferret_find.dart';
import 'package:find/feature/find_feature.dart';
import 'package:flutter/foundation.dart';

/// Which limits and options Settings explains.
enum FindPlatformKind {
  android,
  ios,
  macos,

  /// Windows and Linux: plays a sound, leaves the volume alone.
  desktop;

  static FindPlatformKind get current {
    if (Platform.isAndroid) {
      return android;
    }

    if (Platform.isIOS) {
      return ios;
    }

    if (Platform.isMacOS) {
      return macos;
    }

    return desktop;
  }
}

/// Find my device's settings: ringing on silent with the Do Not Disturb
/// permission flow on Android (re-checked when the app comes back), the
/// torch, the full-screen permission and a test ring.
class FindSettingsViewModel extends ChangeNotifier {
  FindSettingsViewModel(this._feature, {FindPlatformKind? platform})
    : platform = platform ?? FindPlatformKind.current {
    _subscription = _feature.changes.listen((_) => _notify());
  }

  final FindFeature _feature;
  final FindPlatformKind platform;
  late final StreamSubscription<void> _subscription;

  bool _waitingForReturn = false;
  bool _stillOff = false;
  bool _openFailed = false;
  bool _disposed = false;

  bool get ringOnSilent => _feature.settings.ringOnSilent;

  bool get flashTorch => _feature.settings.flashTorch;

  RingAbilities get abilities => _feature.abilities;

  /// Ringing on silent is on, but Android still needs Do Not Disturb access.
  bool get needsDndAccess => ringOnSilent && abilities.missingDndAccess;

  /// The person came back from Settings and access is still off.
  bool get stillOff => _stillOff;

  /// The system settings page could not be opened.
  bool get openFailed => _openFailed;

  bool get isRingingHere => _feature.localRing.isRinging;

  Future<void> setRingOnSilent(bool value) =>
      _feature.settings.setRingOnSilent(value);

  Future<void> setFlashTorch(bool value) =>
      _feature.settings.setFlashTorch(value);

  Future<void> openDndAccess() => _open(_feature.openDndAccessSettings);

  Future<void> openFullScreen() => _open(_feature.openFullScreenSettings);

  Future<void> testRing() async {
    await _feature.testRing();
  }

  /// Call when the app comes back to the front: reads the permissions again.
  Future<void> onResumed() async {
    await _feature.refreshAbilities();
    _stillOff = _waitingForReturn && needsDndAccess;
    _waitingForReturn = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  Future<void> _open(Future<void> Function() open) async {
    _openFailed = false;
    _stillOff = false;

    try {
      await open();
      _waitingForReturn = true;
    } on Object catch (error) {
      printWarning('Opening the system settings failed', error);
      _openFailed = true;
    }

    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
