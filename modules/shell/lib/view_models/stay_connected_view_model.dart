import 'dart:async';

import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';

/// What's still in the way of Ferret staying connected on Android, re-checked
/// whenever the user comes back from a settings screen.
class StayConnectedViewModel extends ChangeNotifier {
  StayConnectedViewModel({FerretSystem? system})
    : _system = system ?? FerretSystem();

  final FerretSystem _system;
  bool _disposed = false;

  bool notificationsAllowed = true;
  bool batteryExempt = true;
  DeviceMaker maker = .other;
  int stopsToday = 0;
  bool canAddTile = false;

  bool get isAndroid => _system.isAndroid;

  /// Nothing left to do, so the card can hide.
  bool get allSet =>
      notificationsAllowed && batteryExempt && stopsToday == 0 && !canAddTile;

  Future<void> refresh() async {
    if (!isAndroid) {
      return;
    }

    notificationsAllowed = await _system.areNotificationsAllowed();
    batteryExempt = await _system.isIgnoringBatteryOptimizations();
    maker = await _system.deviceMaker();
    stopsToday = await _system.serviceStopsToday();
    canAddTile = await _system.canRequestAddTile();
    _notify();
  }

  Future<void> allowNotifications() async {
    await _system.requestNotificationPermission();
    await refresh();
  }

  Future<void> allowBackground() async {
    await _system.requestIgnoreBatteryOptimizations();
    await refresh();
  }

  Future<void> openMakerSettings() => _system.openMakerBatterySettings();

  Future<void> addTile() async {
    await _system.requestAddTile();
    canAddTile = false;
    _notify();
  }

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
