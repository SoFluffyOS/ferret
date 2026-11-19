import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/feature/notifications_feature.dart';
import 'package:notifications/services/services.dart';
import 'package:protocol/notifications.dart';

/// Where the phone is in turning mirroring on.
enum SetupStage {
  /// Mirroring is off: explain it first.
  off,

  /// Mirroring is on but Android doesn't let Ferret read notifications yet.
  needsAccess,

  /// Everything works.
  ready,
}

/// Turns mirroring on for this phone: explainer, notification access,
/// a re-check when the person comes back from Settings, and the restricted
/// settings guide when Android blocks the switch.
class MirrorSetupViewModel extends ChangeNotifier {
  MirrorSetupViewModel({
    required NotificationsFeature feature,
    required NotificationAccess access,
  }) : _feature = feature,
       _access = access {
    _settingsSubscription = feature.host.settings.changes
        .where(MirrorPreferences.owns)
        .listen((_) => _notify());
    unawaited(refresh());
  }

  final NotificationsFeature _feature;
  final NotificationAccess _access;
  late final StreamSubscription<String> _settingsSubscription;

  bool _accessGranted = false;
  bool _checked = false;
  bool _restricted = false;
  bool _waitingForReturn = false;
  bool _stillOff = false;
  bool _openFailed = false;
  bool _disposed = false;

  MirrorPreferences get _preferences => _feature.preferences;

  SetupStage get stage {
    if (!_preferences.enabled) {
      return .off;
    }

    if (!_accessGranted) {
      return .needsAccess;
    }

    return .ready;
  }

  /// Access was read at least once.
  bool get checked => _checked;

  /// The person came back from Settings and access is still off.
  bool get stillOff => _stillOff;

  /// Android probably blocks the access switch; show the guide.
  bool get restricted => _restricted;

  /// Settings could not be opened on this phone.
  bool get openFailed => _openFailed;

  bool get skipWhileUsing => _preferences.skipWhileUsing;

  bool get hideCodes => _preferences.hideCodes;

  AppFilter get appFilter => _preferences.appFilter;

  /// How many apps the filter names: muted ones or picked ones.
  int get namedAppCount => switch (appFilter) {
    .APP_FILTER_ALL_EXCEPT => _preferences.excludedApps.length,
    .APP_FILTER_ONLY => _preferences.allowedApps.length,
    _ => 0,
  };

  /// Re-reads notification access, such as when the app comes back to the
  /// front.
  Future<void> refresh() async {
    final granted = await _guard(_access.isAccessGranted, fallback: false);
    final restricted = switch (granted) {
      true => false,
      false => await _guard(_access.mayBeRestricted, fallback: false),
    };

    _stillOff = _waitingForReturn && !granted;
    _waitingForReturn = false;
    _accessGranted = granted;
    _restricted = restricted;
    _checked = true;
    _notify();
  }

  /// The explainer's button: turns mirroring on and asks for access if it
  /// is still off.
  Future<void> turnOn() async {
    await _preferences.setEnabled(true);
    await refresh();

    if (!_accessGranted) {
      await openAccessSettings();
    }
  }

  Future<void> turnOff() => _preferences.setEnabled(false);

  Future<void> openAccessSettings() => _open(_access.openAccessSettings);

  Future<void> openAppInfo() => _open(_access.openAppInfo);

  Future<void> setSkipWhileUsing(bool value) =>
      _preferences.setSkipWhileUsing(value);

  Future<void> setHideCodes(bool value) => _preferences.setHideCodes(value);

  /// Call when the app comes back to the front.
  Future<void> onResumed() async {
    if (!_waitingForReturn && stage != .needsAccess) {
      return;
    }

    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_settingsSubscription.cancel());
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> _open(Future<void> Function() open) async {
    _openFailed = false;
    _stillOff = false;

    try {
      await open();
      _waitingForReturn = true;
    } on Object catch (error) {
      printWarning('Opening notification settings failed', error);
      _openFailed = true;
    }

    _notify();
  }

  Future<bool> _guard(
    Future<bool> Function() read, {
    required bool fallback,
  }) async {
    try {
      return await read();
    } on Object catch (error) {
      printWarning('Reading notification access failed', error);
      return fallback;
    }
  }
}
