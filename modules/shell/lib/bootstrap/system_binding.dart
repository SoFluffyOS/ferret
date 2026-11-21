import 'dart:async';

import 'package:engine/engine.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/services/services.dart';

/// Connects Ferret to the operating system: keeps it running on Android,
/// shows who is connected in the notification and the Quick Settings tile,
/// follows pauses chosen from the notification, and reconnects right away
/// after sleep, a network change, or coming back to the app.
class SystemBinding with WidgetsBindingObserver {
  SystemBinding({
    required this.engine,
    required this.host,
    required this.pause,
    FerretSystem? system,
  }) : _system = system ?? FerretSystem();

  /// Keep Ferret running in the background on Android (default on).
  static const backgroundServiceKey = 'system.background_service';

  /// Start Ferret when the phone starts. Off until the person says yes to
  /// the Stay connected card's question; see [BootChoice].
  static const startOnBootKey = BootChoice.startKey;

  /// Network callbacks come in bursts; one reconnect covers them. Android
  /// says a network is there before it has handed this device an address,
  /// so the reconnect runs again a little later rather than leaving it to
  /// the slow redial backoff.
  static const _reconnectAfter = [
    Duration(milliseconds: 500),
    Duration(seconds: 3),
    Duration(seconds: 8),
  ];

  final FerretEngine engine;
  final EngineHost host;
  final PauseController pause;
  final FerretSystem _system;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  final List<Timer> _reconnectTimers = [];
  List<String>? _shownDevices;
  PauseState? _shownPause;

  Future<void> start() async {
    _subscriptions
      ..add(_system.networkChanges.listen(_onNetworkChange))
      ..add(_system.pauseChanges.listen(_onSystemPause))
      ..add(engine.settings.changes.listen(_onSettingChanged));
    WidgetsBinding.instance.addObserver(this);
    host.addListener(_onHostChanged);
    pause.addListener(_onPauseChanged);

    if (!_system.isAndroid) {
      return;
    }

    await BootChoice(
      engine.settings,
    ).adopt(hadDevices: engine.trustStore.devices.isNotEmpty);
    await _applyServiceSettings();
    await _restorePause();
    await _showDevices();
  }

  Future<void> dispose() async {
    _cancelReconnects();
    WidgetsBinding.instance.removeObserver(this);
    host.removeListener(_onHostChanged);
    pause.removeListener(_onPauseChanged);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .hidden) {
      host.settleOrder();
    }

    if (state == .resumed) {
      _scheduleReconnect();
      unawaited(_keepServiceRunning());
    }
  }

  /// Android may have taken the service down while Ferret was out of sight,
  /// such as with battery use set to Restricted. Back on screen is the one
  /// moment an app may start it again.
  Future<void> _keepServiceRunning() async {
    if (!_system.isAndroid) {
      return;
    }

    await _applyServiceSettings();
  }

  void _onNetworkChange(NetworkChange change) {
    if (change == .lost) {
      return;
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _cancelReconnects();
    for (final delay in _reconnectAfter) {
      _reconnectTimers.add(
        Timer(delay, () {
          if (pause.isPaused || !engine.isRunning) {
            return;
          }

          unawaited(engine.reconnectNow());
        }),
      );
    }
  }

  void _cancelReconnects() {
    for (final timer in _reconnectTimers) {
      timer.cancel();
    }
    _reconnectTimers.clear();
  }

  void _onHostChanged() => unawaited(_showDevices());

  Future<void> _showDevices() async {
    final names = [
      for (final status in host.devices)
        if (status.isConnected) status.device.name,
    ];
    if (listEquals(names, _shownDevices)) {
      return;
    }

    _shownDevices = names;
    await _system.updateStatus(names);
  }

  void _onPauseChanged() => unawaited(_showPause());

  Future<void> _showPause() async {
    final state = PauseState(isPaused: pause.isPaused, until: pause.until);
    if (state == _shownPause) {
      return;
    }

    _shownPause = state;
    await _system.setPause(state);
    if (state.isPaused) {
      await _system.releaseMulticastLock();
      return;
    }

    await _system.acquireMulticastLock();
  }

  void _onSystemPause(PauseState state) => unawaited(_follow(state));

  /// A pause chosen while Dart wasn't running, such as from the
  /// notification before Android restarted the app, still holds.
  Future<void> _restorePause() async {
    await _follow(await _system.pauseState());
  }

  Future<void> _follow(PauseState state) async {
    _shownPause = state;
    if (!state.isPaused) {
      await pause.resume();
      return;
    }

    final until = state.until;
    if (until == null) {
      await pause.pause();
      return;
    }

    final left = until.difference(DateTime.now());
    if (left <= Duration.zero) {
      await pause.resume();
      return;
    }

    await pause.pause(duration: left);
  }

  void _onSettingChanged(String key) {
    if (key != backgroundServiceKey && key != startOnBootKey) {
      return;
    }

    unawaited(_applyServiceSettings());
  }

  Future<void> _applyServiceSettings() async {
    final settings = engine.settings;
    final background = settings.get<bool>(backgroundServiceKey) ?? true;
    final onBoot = BootChoice(settings).startsOnBoot;

    await _system.setStartOnBoot(onBoot);
    if (!background) {
      await _system.stopService();
      return;
    }

    if (await _system.isServiceRunning()) {
      return;
    }

    await _system.startService();
  }
}
