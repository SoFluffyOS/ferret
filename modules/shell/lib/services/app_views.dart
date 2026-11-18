import 'dart:async';
import 'dart:ui';

import 'package:core/core.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/services/active_navigator_key.dart';

/// The Flutter views Ferret draws on this device. Everywhere there is the
/// main one; on a Mac that is the menubar popover, and the desktop window
/// adds a second while it is open. Both show the same running app, each
/// with its own navigator, and this says which one the person is looking
/// at, so a prompt or a pushed page lands there.
class AppViews extends ChangeNotifier with WidgetsBindingObserver {
  AppViews({
    required FerretMenubar menubar,
    required SettingsStore settings,
    PlatformDispatcher? dispatcher,
    this.desktopWindow,
  }) : _menubar = menubar,
       _settings = settings,
       _dispatcher = dispatcher ?? PlatformDispatcher.instance;

  /// Settings key for when Ferret shows in the Dock: a [MenubarDockMode]
  /// by name.
  static const dockModeKey = 'shell.dock_icon';

  final FerretMenubar _menubar;
  final SettingsStore _settings;

  /// The Windows and Linux window, which may sit hidden in the tray.
  final DesktopWindow? desktopWindow;
  final PlatformDispatcher _dispatcher;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// The navigator of the main view.
  final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey(
    debugLabel: 'main view',
  );

  /// The navigator of the view the person is looking at. Not for a widget:
  /// see [ActiveNavigatorKey].
  late final GlobalKey<NavigatorState> navigatorKey = ActiveNavigatorKey(
    () => activeNavigatorKey,
  );

  GlobalKey<NavigatorState> _windowNavigatorKey = GlobalKey();
  bool _canOpenWindow = false;
  int? _windowViewId;
  FlutterView? _window;
  bool _isWindowFocused = false;
  bool _isPopoverShown = false;
  bool _started = false;

  /// The view Ferret always has: the popover on a Mac, the app's window or
  /// screen elsewhere.
  FlutterView get main => _dispatcher.implicitView ?? _dispatcher.views.first;

  /// The desktop window's view while it is open.
  FlutterView? get window => _window;

  /// The navigator of the desktop window. Each time the window opens it is
  /// a new one, starting at home.
  GlobalKey<NavigatorState> get windowNavigatorKey => _windowNavigatorKey;

  /// Whether Ferret can open a desktop window next to its main view.
  bool get canOpenWindow => _canOpenWindow;

  bool get isWindowOpen => _window != null;

  /// Whether the Dock shows Ferret all the time, and not only while the
  /// window is open.
  bool get alwaysInDock => _dockMode == .always;

  /// The window when it is open, unless the popover is the one in front.
  GlobalKey<NavigatorState> get activeNavigatorKey {
    if (_window == null) {
      return mainNavigatorKey;
    }

    if (_isPopoverShown && !_isWindowFocused) {
      return mainNavigatorKey;
    }

    return _windowNavigatorKey;
  }

  Future<void> start() async {
    if (_started || !_menubar.isSupported) {
      return;
    }

    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _subscriptions
      ..add(_menubar.visibility.listen(_onPopoverVisibility))
      ..add(_menubar.windowEvents.listen(_onWindowEvent));
    _canOpenWindow = await _menubar.isWindowSupported();
    await _menubar.setDockMode(_dockMode);
    // After a hot restart the window is still there, with nobody drawing it.
    if (await _menubar.isWindowOpen()) {
      await openWindow();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }

    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }

  /// Opens the desktop window, or brings it to the front.
  Future<void> openWindow() async {
    final viewId = await _menubar.openWindow();
    if (viewId == null) {
      return;
    }

    _follow(viewId);
  }

  /// Opens the window for something that needs its room, and puts the
  /// popover away: the person asked for one place, not two.
  Future<void> moveToWindow() async {
    await openWindow();
    if (_isPopoverShown) {
      await _menubar.hide();
    }
  }

  Future<void> closeWindow() => _menubar.closeWindow();

  /// Brings Ferret in front of the person: the window when it is open,
  /// otherwise the popover.
  Future<void> reveal() async {
    if (_window == null) {
      await desktopWindow?.show();
      await _menubar.show();
      return;
    }

    if (_isPopoverShown) {
      return;
    }

    await openWindow();
  }

  Future<void> setAlwaysInDock(bool always) async {
    final mode = switch (always) {
      true => MenubarDockMode.always,
      false => MenubarDockMode.whenWindowOpen,
    };
    await _settings.set(dockModeKey, mode.name);
    await _menubar.setDockMode(mode);
    notifyListeners();
  }

  /// Views come and go through the engine, a moment apart from the
  /// plugin's own events, so this is where the window's view really
  /// appears and disappears.
  @override
  void didChangeMetrics() => _syncWindow();

  MenubarDockMode get _dockMode =>
      MenubarDockMode.values.asNameMap()[_settings.get<String>(dockModeKey)] ??
      .whenWindowOpen;

  void _onPopoverVisibility(bool shown) => _isPopoverShown = shown;

  void _onWindowEvent(MenubarWindowEvent event) {
    switch (event) {
      case MenubarWindowOpened(:final viewId):
        _follow(viewId);
      case MenubarWindowFocusChanged(:final focused):
        _isWindowFocused = focused;
      case MenubarWindowClosed(:final viewId):
        _forget(viewId);
    }
  }

  void _follow(int viewId) {
    if (_windowViewId != viewId) {
      _windowViewId = viewId;
      _windowNavigatorKey = GlobalKey();
      _window = null;
    }

    _syncWindow();
  }

  void _forget(int viewId) {
    if (_windowViewId != viewId) {
      return;
    }

    _windowViewId = null;
    _isWindowFocused = false;
    if (_window == null) {
      return;
    }

    _window = null;
    notifyListeners();
  }

  void _syncWindow() {
    final viewId = _windowViewId;
    if (viewId == null) {
      return;
    }

    final view = _dispatcher.view(id: viewId);
    if (view == _window) {
      return;
    }

    if (view == null) {
      _forget(viewId);
      return;
    }

    _window = view;
    notifyListeners();
  }
}
