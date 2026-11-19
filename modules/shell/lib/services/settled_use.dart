import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:shell/services/device_preferences.dart';

/// When each device was last used here, as the device list sorts by it. A
/// new use moves its device only once nothing was used for [delay], or the
/// list is put away ([settle]), so a row doesn't slide out from under the
/// pointer right after one of its buttons was pressed.
class SettledUse {
  SettledUse(this._settings, {required this.onSettled, this.delay = after})
    : _settled = _read(_settings);

  static const after = Duration(seconds: 30);

  final SettingsStore _settings;
  final VoidCallback onSettled;
  final Duration delay;
  Map<String, dynamic> _settled;
  Timer? _timer;

  /// Last uses as the list shows them, by device id.
  Map<String, dynamic> get lastUsed => _settled;

  /// A device was just used: its row waits [delay] before it moves.
  void used() {
    _timer?.cancel();
    _timer = Timer(delay, settle);
  }

  /// Lets the list catch up with every use now.
  void settle() {
    _timer?.cancel();
    _timer = null;

    final current = _read(_settings);
    if (mapEquals(current, _settled)) {
      return;
    }

    _settled = current;
    onSettled();
  }

  void dispose() => _timer?.cancel();

  static Map<String, dynamic> _read(SettingsStore settings) => {
    ...?settings.get<Map<String, dynamic>>(DevicePreferences.lastUsedKey),
  };
}
