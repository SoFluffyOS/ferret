import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';

/// Asks the system once whether Ferret may show notifications, at the first
/// moment they mean something: when a device is paired, or at start when
/// one already is. Android asks from its own Stay connected card instead.
class NotificationPermission {
  NotificationPermission({
    required Stream<List<DeviceStatus>> devices,
    required bool Function() hasDevices,
    required SettingsStore settings,
    required Future<void> Function() request,
    bool asksHere = true,
  }) : _devices = devices,
       _hasDevices = hasDevices,
       _settings = settings,
       _request = request,
       _asksHere = asksHere;

  /// Setting: set once the system was asked, so it is never asked again.
  static const askedKey = 'shell.notification_permission_asked';

  final Stream<List<DeviceStatus>> _devices;
  final bool Function() _hasDevices;
  final SettingsStore _settings;
  final Future<void> Function() _request;
  final bool _asksHere;
  StreamSubscription<List<DeviceStatus>>? _subscription;

  Future<void> start() async {
    final alreadyAsked = _settings.get<bool>(askedKey) ?? false;
    if (!_asksHere || alreadyAsked) {
      return;
    }

    if (_hasDevices()) {
      await _ask();
      return;
    }

    _subscription = _devices.listen((devices) {
      if (devices.isEmpty) {
        return;
      }

      unawaited(_ask());
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _ask() async {
    await dispose();
    await _settings.set(askedKey, true);
    await _request();
  }
}
