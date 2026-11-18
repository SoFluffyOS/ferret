import 'dart:async';

import 'package:ferret_system/src/device_maker.dart';
import 'package:ferret_system/src/messages.g.dart';
import 'package:ferret_system/src/pause_state.dart';
import 'package:ferret_system/src/polling_network_watcher.dart';
import 'package:ferret_system/src/system_action.dart';
import 'package:ferret_system/src/system_platform.dart';
import 'package:flutter/foundation.dart';

/// System hooks for Ferret: the Android foreground service, its notification
/// and Quick Settings tile, battery settings, and the network and wake events
/// that make Ferret reconnect. Calls do nothing where a platform has no such
/// thing, and there is one instance per app.
class FerretSystem implements SystemFlutterApi {
  factory FerretSystem() => _instance ??= FerretSystem._(
    api: SystemHostApi(),
    platform: SystemPlatform.current,
    registerCallbacks: true,
  );

  @visibleForTesting
  factory FerretSystem.forTesting({
    required SystemHostApi api,
    required SystemPlatform platform,
    PollingNetworkWatcher? pollingWatcher,
  }) => FerretSystem._(
    api: api,
    platform: platform,
    registerCallbacks: false,
    pollingWatcher: pollingWatcher,
  );

  FerretSystem._({
    required SystemHostApi api,
    required this.platform,
    required bool registerCallbacks,
    PollingNetworkWatcher? pollingWatcher,
  }) : _api = api,
       _pollingWatcher = pollingWatcher {
    _actions = .broadcast(onListen: _onActionsListened);
    _networkChanges = .broadcast(
      onListen: _onNetworkListened,
      onCancel: _onNetworkCancelled,
    );
    if (registerCallbacks && _hasNativeEvents) {
      SystemFlutterApi.setUp(this);
    }
  }

  static FerretSystem? _instance;

  final SystemPlatform platform;
  final SystemHostApi _api;
  final StreamController<PauseState> _pauseChanges = .broadcast();
  late final StreamController<SystemAction> _actions;
  late final StreamController<NetworkChange> _networkChanges;
  PollingNetworkWatcher? _pollingWatcher;
  StreamSubscription<NetworkChange>? _pollingSubscription;
  bool _actionsListening = false;

  bool get isAndroid => platform == .android;

  bool get _hasNativeEvents => platform == .android || platform == .macos;

  /// What the user asked for from the tile or the notification, such as
  /// [SystemAction.clipboardSend]. Actions from before anyone listened are
  /// delivered to the first listener.
  Stream<SystemAction> get actions => _actions.stream;

  /// Network changes and wake from sleep, for reconnecting right away. Only
  /// watched while someone listens.
  Stream<NetworkChange> get networkChanges => _networkChanges.stream;

  /// Pauses and resumes chosen outside the app, such as the notification's
  /// Pause action, or a pause that ran out.
  Stream<PauseState> get pauseChanges => _pauseChanges.stream;

  /// Android drops multicast packets unless an app holds this lock, which
  /// discovery needs. Release it when Ferret stops listening.
  Future<void> acquireMulticastLock() => _android(_api.acquireMulticastLock);

  Future<void> releaseMulticastLock() => _android(_api.releaseMulticastLock);

  /// Starts the foreground service that keeps Ferret connected while the app
  /// is closed, and remembers to keep it running.
  Future<void> startService() => _android(_api.startService);

  /// Stops the service and remembers that the user turned it off.
  Future<void> stopService() => _android(_api.stopService);

  Future<bool> isServiceRunning() =>
      _androidValue(_api.isServiceRunning, fallback: false);

  /// Whether the service starts after the phone restarts.
  Future<void> setStartOnBoot(bool enabled) =>
      _android(() => _api.setStartOnBoot(enabled));

  /// Shows [connectedDevices] in the service notification and the tile.
  Future<void> updateStatus(List<String> connectedDevices) =>
      _android(() => _api.updateStatus(connectedDevices));

  /// Shows a pause chosen in the app in the notification and the tile, and
  /// makes sure it ends on time even if the app was stopped meanwhile.
  Future<void> setPause(PauseState pause) => _android(
    () => _api.setPause(
      PauseMessage(
        paused: pause.isPaused,
        untilMs: pause.until?.millisecondsSinceEpoch,
      ),
    ),
  );

  Future<PauseState> pauseState() async {
    if (!isAndroid) {
      return PauseState.running;
    }

    return _pauseFrom(await _api.pauseState());
  }

  /// Whether Android's battery optimization leaves Ferret alone. Always true
  /// off Android.
  Future<bool> isIgnoringBatteryOptimizations() =>
      _androidValue(_api.isIgnoringBatteryOptimizations, fallback: true);

  /// Shows Android's dialog to exempt Ferret from battery optimization.
  /// Returns false when nothing could be shown.
  Future<bool> requestIgnoreBatteryOptimizations() =>
      _androidValue(_api.requestIgnoreBatteryOptimizations, fallback: false);

  Future<DeviceMaker> deviceMaker() async {
    if (!isAndroid) {
      return DeviceMaker.other;
    }

    return DeviceMaker.fromManufacturer(await _api.manufacturer());
  }

  /// Opens the maker's own autostart or background screen, or the app's
  /// settings page. Returns false when nothing opened.
  Future<bool> openMakerBatterySettings() =>
      _androidValue(_api.openMakerBatterySettings, fallback: false);

  /// When Android stopped Ferret's service without being asked, over the
  /// last week.
  Future<List<DateTime>> recentServiceStops() async {
    if (!isAndroid) {
      return const [];
    }

    final stops = await _api.recentServiceStops();
    return [for (final ms in stops) DateTime.fromMillisecondsSinceEpoch(ms)];
  }

  /// How many times Android stopped Ferret since midnight, for "Android
  /// stopped Ferret 3 times today".
  Future<int> serviceStopsToday({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    final stops = await recentServiceStops();
    return stops.where((stop) => !stop.isBefore(midnight)).length;
  }

  /// Whether [requestAddTile] can show Android's "Add tile" prompt (13+).
  Future<bool> canRequestAddTile() =>
      _androidValue(_api.canRequestAddTile, fallback: false);

  /// Asks to add the Ferret tile to Quick Settings.
  Future<AddTileResult> requestAddTile() =>
      _androidValue(_api.requestAddTile, fallback: AddTileResult.unsupported);

  /// Whether Ferret may show notifications, which the service notification
  /// needs to be visible on Android 13+.
  Future<bool> areNotificationsAllowed() =>
      _androidValue(_api.areNotificationsAllowed, fallback: true);

  Future<bool> requestNotificationPermission() =>
      _androidValue(_api.requestNotificationPermission, fallback: true);

  /// Passes on what the user picked outside the app's window, such as the
  /// desktop tray's Send clipboard, the same way the tile's actions come.
  void emitAction(SystemAction action) => _actions.add(action);

  @override
  void onAction(SystemActionMessage action) =>
      _actions.add(SystemAction(action.id, Map.of(action.data)));

  @override
  void onNetworkChange(NetworkChange change) => _networkChanges.add(change);

  @override
  void onPauseChanged(PauseMessage pause) =>
      _pauseChanges.add(_pauseFrom(pause));

  void _onActionsListened() {
    if (_actionsListening || !isAndroid) {
      return;
    }

    _actionsListening = true;
    unawaited(_api.listenForActions());
  }

  void _onNetworkListened() {
    if (_hasNativeEvents) {
      unawaited(_api.setNetworkWatching(true));
      return;
    }

    if (platform != .desktop) {
      return;
    }

    final watcher = _pollingWatcher ??= PollingNetworkWatcher();
    _pollingSubscription = watcher.changes.listen(_networkChanges.add);
    watcher.start();
  }

  void _onNetworkCancelled() {
    if (_hasNativeEvents) {
      unawaited(_api.setNetworkWatching(false));
      return;
    }

    _pollingWatcher?.stop();
    unawaited(_pollingSubscription?.cancel());
    _pollingSubscription = null;
  }

  PauseState _pauseFrom(PauseMessage pause) => PauseState(
    isPaused: pause.paused,
    until: switch (pause.untilMs) {
      final ms? when pause.paused => DateTime.fromMillisecondsSinceEpoch(ms),
      _ => null,
    },
  );

  Future<void> _android(Future<void> Function() call) async {
    if (!isAndroid) {
      return;
    }

    await call();
  }

  Future<T> _androidValue<T>(
    Future<T> Function() call, {
    required T fallback,
  }) async {
    if (!isAndroid) {
      return fallback;
    }

    return call();
  }
}
