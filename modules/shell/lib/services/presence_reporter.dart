import 'dart:async';
import 'dart:io' as io;

import 'package:engine/engine.dart';
import 'package:flutter/widgets.dart';
import 'package:protocol/protocol.dart';

/// Tells paired devices whether someone is using this one, so suggestions
/// such as "Continue on…" show up where the person is.
///
/// Phones count as in use while Ferret is in front. Computers count as in
/// use while they're awake, since Ferret lives in the menubar or tray.
class PresenceReporter with WidgetsBindingObserver {
  PresenceReporter(this._engine);

  final FerretEngine _engine;

  bool get _isPhoneOrTablet => io.Platform.isAndroid || io.Platform.isIOS;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _report(
      active:
          !_isPhoneOrTablet ||
          _isForeground(WidgetsBinding.instance.lifecycleState),
    );
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isPhoneOrTablet) {
      return;
    }

    unawaited(_report(active: _isForeground(state)));
  }

  bool _isForeground(AppLifecycleState? state) =>
      state == null || state == .resumed;

  Future<void> _report({required bool active}) async {
    final current = _engine.localPresence;
    if (current.userActive == active && current.screenOn == active) {
      return;
    }

    await _engine.updatePresence(
      current.deepCopy()
        ..userActive = active
        ..screenOn = active,
    );
  }
}
