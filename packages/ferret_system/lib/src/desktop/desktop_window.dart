import 'dart:async';

import 'package:ferret_system/src/desktop/tray_menu_item.dart';
import 'package:flutter/services.dart';

/// The Windows and Linux window, which the app's own runner draws: whether
/// closing it hides Ferret to the tray or quits, showing and hiding it, and
/// the runner's tray icon on Windows. The runner keeps the window's size
/// and place between runs by itself.
///
/// Runner methods: `window.setHideOnClose {value}`, `window.show`,
/// `window.hide`, `window.toggle`, `window.quit`, `window.startedHidden`,
/// `tray.set {tooltip, items}` (Windows), `tray.remove` (Windows).
/// Runner calls: `window.closedToTray`, `tray.activate`, `tray.select {id}`.
class DesktopWindow {
  factory DesktopWindow() => _instance ??= DesktopWindow.withChannel(
    const MethodChannel(channelName),
  );

  DesktopWindow.withChannel(this._channel) {
    _channel.setMethodCallHandler(_onCall);
  }

  static const channelName = 'io.sofluffy.ferret/desktop';

  static DesktopWindow? _instance;

  final MethodChannel _channel;
  final StreamController<void> _closedToTray = .broadcast();
  final StreamController<void> _trayActivations = .broadcast();
  final StreamController<String> _traySelections = .broadcast();

  /// The window was closed and Ferret stayed in the tray.
  Stream<void> get closedToTray => _closedToTray.stream;

  /// The runner's tray icon was clicked (Windows).
  Stream<void> get trayActivations => _trayActivations.stream;

  /// A line of the runner's tray menu was picked, by its id (Windows).
  Stream<String> get traySelections => _traySelections.stream;

  /// Closing the window hides it when [hide] is true, and quits otherwise.
  Future<void> setHideOnClose(bool hide) =>
      _call('window.setHideOnClose', {'value': hide});

  Future<void> show() => _call('window.show');

  Future<void> hide() => _call('window.hide');

  /// Hides the window when it is in front, shows it otherwise.
  Future<void> toggle() => _call('window.toggle');

  /// Remembers the window's place and ends Ferret.
  Future<void> quit() => _call('window.quit');

  /// Whether Ferret was started with `--hidden`, as autostart does, so the
  /// window stayed hidden.
  Future<bool> startedHidden() async =>
      await _value<bool>('window.startedHidden') ?? false;

  /// Shows or updates the runner's tray icon. False where there is none.
  Future<bool> setTray(String tooltip, List<TrayMenuItem> items) async =>
      await _value<bool>('tray.set', {
        'tooltip': tooltip,
        'items': [for (final item in items) item.toMap()],
      }) ??
      false;

  Future<void> removeTray() => _call('tray.remove');

  Future<void> _call(String method, [Object? arguments]) async {
    await _value<Object>(method, arguments);
  }

  /// A runner from before these methods simply doesn't answer, so
  /// everything here does nothing there.
  Future<T?> _value<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<Object?> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'window.closedToTray':
        _closedToTray.add(null);
      case 'tray.activate':
        _trayActivations.add(null);
      case 'tray.select':
        if (call.arguments case {'id': final String id}) {
          _traySelections.add(id);
        }
    }

    return null;
  }
}
