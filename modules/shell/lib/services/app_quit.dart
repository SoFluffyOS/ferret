import 'dart:async';
import 'dart:ui';

import 'package:core/core.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Ends Ferret cleanly on every way out: features stop and connected
/// devices get a goodbye, so they show this one offline at once instead of
/// after the keep-alive runs out.
///
/// Quit from Ferret's own menus goes through [quit]. Quits the system starts
/// (⌘Q, the Dock, closing the last window, logging out) arrive as an exit
/// request and wait for the same shutdown. On Android the service keeps
/// Ferret running after the app closes, so nothing is shut down there.
class AppQuit with WidgetsBindingObserver {
  AppQuit({
    Future<void> Function()? shutdown,
    Future<void> Function()? exitPlatform,
    this.timeout = const Duration(milliseconds: 1500),
  }) : _shutdown = shutdown,
       _exitPlatform = exitPlatform ?? _exitThisPlatform;

  /// The longest a quit waits for the goodbyes before it ends anyway.
  final Duration timeout;

  final Future<void> Function()? _shutdown;
  final Future<void> Function() _exitPlatform;
  Future<void>? _shuttingDown;

  static bool get _keepsRunning => defaultTargetPlatform == .android;

  void start() => WidgetsBinding.instance.addObserver(this);

  void dispose() => WidgetsBinding.instance.removeObserver(this);

  /// Stops features and says goodbye, once, giving up after [timeout].
  Future<void> shutDown() => _shuttingDown ??= _shutDownOnce();

  /// Shuts down, then ends the app the way this platform does.
  Future<void> quit() async {
    if (!_keepsRunning) {
      await shutDown();
    }

    await _exitPlatform();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    if (!_keepsRunning) {
      await shutDown();
    }

    return .exit;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != .detached || _keepsRunning) {
      return;
    }

    unawaited(shutDown());
  }

  Future<void> _shutDownOnce() async {
    final shutdown = _shutdown;
    if (shutdown == null) {
      return;
    }

    try {
      await shutdown().timeout(timeout);
    } on TimeoutException {
      printWarning('Quit without every goodbye: shutdown took over $timeout');
    } on Object catch (error) {
      printWarning('Shutdown failed while quitting', error);
    }
  }

  /// On Windows and Linux the window may only be hiding in the tray, so the
  /// runner quits, which also remembers where the window was.
  static Future<void> _exitThisPlatform() async {
    if (defaultTargetPlatform == .windows || defaultTargetPlatform == .linux) {
      await DesktopWindow().quit();
      return;
    }

    await SystemNavigator.pop();
  }
}
