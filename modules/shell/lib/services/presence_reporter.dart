import 'dart:async';
import 'dart:io' as io;

import 'package:engine/engine.dart';
import 'package:ferret_battery/ferret_battery.dart';
import 'package:flutter/widgets.dart';
import 'package:protocol/protocol.dart';

/// Tells paired devices whether someone is using this one, so suggestions
/// such as "Continue on…" show up where the person is.
///
/// Phones count as in use while Ferret is in front. Computers count as in
/// use while the person is at the screen: a locked screen, or another
/// account in front, reads as away on their other devices.
class PresenceReporter with WidgetsBindingObserver {
  PresenceReporter(
    this._engine, {
    bool Function()? isAtScreen,
    Stream<bool>? atScreenChanges,
    bool? isPhoneOrTablet,
    BatterySource? battery,
  }) : _battery = battery,
       _isAtScreen = isAtScreen ?? _always,
       _atScreenChanges = atScreenChanges,
       _isPhoneOrTablet =
           isPhoneOrTablet ?? (io.Platform.isAndroid || io.Platform.isIOS);

  final FerretEngine _engine;

  /// Where this device's battery comes from; null sends none.
  final BatterySource? _battery;
  StreamSubscription<BatteryLevel?>? _batteryChanges;

  /// Battery levels go out in steps this big, so a draining battery
  /// doesn't message every device at each percent.
  static const batteryStep = 5;

  /// Below this every percent goes out, so the low battery notice on the
  /// other devices says 15% when it is 15%.
  static const batteryLowRange = 20;

  /// Whether the screen is unlocked with this account in front.
  final bool Function() _isAtScreen;
  final Stream<bool>? _atScreenChanges;
  final bool _isPhoneOrTablet;
  StreamSubscription<bool>? _screen;

  static bool _always() => true;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _startBattery();
    if (_isPhoneOrTablet) {
      await _report(
        active: _isForeground(WidgetsBinding.instance.lifecycleState),
      );
      return;
    }

    _screen = _atScreenChanges?.listen(
      (isAtScreen) => unawaited(_report(active: isAtScreen, away: !isAtScreen)),
    );
    final isAtScreen = _isAtScreen();
    await _report(active: isAtScreen, away: !isAtScreen);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_screen?.cancel());
    unawaited(_batteryChanges?.cancel());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isPhoneOrTablet) {
      return;
    }

    unawaited(_report(active: _isForeground(state)));
  }

  Future<void> _startBattery() async {
    final battery = _battery;
    if (battery == null) {
      return;
    }

    await reportBattery(await battery.read());
    _batteryChanges = battery.changes.listen(
      (level) => unawaited(reportBattery(level)),
    );
  }

  /// Sends [level] when it crossed a [batteryStep] (each percent once it
  /// runs low), or started or stopped charging. Null means no battery: -1.
  @visibleForTesting
  Future<void> reportBattery(BatteryLevel? level) async {
    final current = _engine.localPresence;
    final percent = level?.percent ?? -1;
    final charging = level?.charging ?? false;
    final sameStep = switch ((current.batteryPercent, percent)) {
      (< 0, < 0) => true,
      (< 0, _) || (_, < 0) => false,
      (final sent, final now) when now <= batteryLowRange => sent == now,
      (final sent, final now) => sent ~/ batteryStep == now ~/ batteryStep,
    };
    if (sameStep && current.charging == charging) {
      return;
    }

    await _engine.updatePresence(
      current.deepCopy()
        ..batteryPercent = percent
        ..charging = charging,
    );
  }

  bool _isForeground(AppLifecycleState? state) =>
      state == null || state == .resumed;

  Future<void> _report({required bool active, bool away = false}) async {
    final current = _engine.localPresence;
    if (current.userActive == active &&
        current.screenOn == active &&
        current.away == away) {
      return;
    }

    await _engine.updatePresence(
      current.deepCopy()
        ..userActive = active
        ..screenOn = active
        ..away = away,
    );
  }
}
