import 'dart:async';
import 'dart:io' as io;

import 'package:engine/engine.dart';
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
  }) : _isAtScreen = isAtScreen ?? _always,
       _atScreenChanges = atScreenChanges,
       _isPhoneOrTablet =
           isPhoneOrTablet ?? (io.Platform.isAndroid || io.Platform.isIOS);

  final FerretEngine _engine;

  /// Whether the screen is unlocked with this account in front.
  final bool Function() _isAtScreen;
  final Stream<bool>? _atScreenChanges;
  final bool _isPhoneOrTablet;
  StreamSubscription<bool>? _screen;

  static bool _always() => true;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isPhoneOrTablet) {
      return;
    }

    unawaited(_report(active: _isForeground(state)));
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
