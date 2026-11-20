import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:shell/services/services.dart';

/// What's still in the way of Ferret staying connected on Android, re-checked
/// whenever the user comes back from a settings screen.
class StayConnectedViewModel extends ChangeNotifier {
  StayConnectedViewModel({FerretSystem? system, SettingsStore? settings})
    : _system = system ?? FerretSystem(),
      _boot = switch (settings) {
        final settings? => BootChoice(settings),
        null => null,
      };

  final FerretSystem _system;
  final BootChoice? _boot;
  bool _disposed = false;

  bool notificationsAllowed = true;
  bool batteryExempt = true;

  /// Battery use set to Restricted: Android takes the service down whenever
  /// the app leaves the screen, whatever else is allowed.
  bool backgroundRestricted = false;
  DeviceMaker maker = .other;
  int stopsToday = 0;

  bool get isAndroid => _system.isAndroid;

  /// Whether to ask "Start Ferret when the phone restarts?": until it is
  /// answered once, here or with the switch in Settings.
  bool get asksAboutBoot => _boot?.needsAnswer ?? false;

  /// Nothing left to do, so the card can hide.
  bool get allSet =>
      notificationsAllowed &&
      batteryExempt &&
      !backgroundRestricted &&
      stopsToday == 0 &&
      !asksAboutBoot;

  /// Whether to show the maker's own steps: its killer can't be read, so
  /// they show while something else says Ferret is being stopped.
  bool get showsMakerSteps =>
      maker.hasExtraKiller &&
      (stopsToday > 0 || !batteryExempt || backgroundRestricted);

  Future<void> refresh() async {
    if (!isAndroid) {
      return;
    }

    notificationsAllowed = await _system.areNotificationsAllowed();
    batteryExempt = await _system.isIgnoringBatteryOptimizations();
    backgroundRestricted = await _system.isBackgroundRestricted();
    maker = await _system.deviceMaker();
    stopsToday = await _system.serviceStopsToday();
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

  /// Keeps the answer; the system binding turns the boot start on or off
  /// from the setting.
  Future<void> answerBoot({required bool start}) async {
    await _boot?.answer(start: start);
    _notify();
  }

  Future<void> openAppSettings() => _system.openAppSettings();

  Future<void> openMakerSettings() => _system.openMakerBatterySettings();

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
