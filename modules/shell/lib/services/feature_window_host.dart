import 'dart:async';
import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The window a feature opened for itself, such as a phone's screen on a
/// Mac: one more Flutter view next to the popover and the desktop window,
/// showing the same running app. This says which view it is and what the
/// feature wants drawn in it.
class FeatureWindowHost extends ChangeNotifier
    with WidgetsBindingObserver
    implements FeatureWindows {
  FeatureWindowHost({
    required FerretMenubar menubar,
    PlatformDispatcher? dispatcher,
  }) : _menubar = menubar,
       _dispatcher = dispatcher ?? PlatformDispatcher.instance;

  final FerretMenubar _menubar;
  final PlatformDispatcher _dispatcher;
  StreamSubscription<int>? _closed;
  bool _canOpen = false;
  bool _started = false;
  FeatureWindow? _window;
  int? _viewId;
  FlutterView? _view;

  @override
  bool get canOpen => _canOpen;

  @override
  String? get openId => _window?.id;

  /// What the feature wants drawn in [view].
  FeatureWindow? get window => _window;

  /// The window's view, once Flutter has it.
  FlutterView? get view => _view;

  Future<void> start() async {
    if (_started || !_menubar.isSupported) {
      return;
    }

    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _closed = _menubar.pictureWindowClosed.listen(_forget);
    _canOpen = await _menubar.isWindowSupported();
    // After a hot restart the window is still there, with nobody drawing it.
    await _menubar.closePictureWindow();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }

    unawaited(_closed?.cancel());
    super.dispose();
  }

  @override
  Future<bool> open(FeatureWindow window) async {
    if (!_canOpen) {
      return false;
    }

    if (_window?.id == window.id) {
      await _menubar.focusPictureWindow();
      return true;
    }

    // What the window showed goes before the window does, so nothing draws
    // into a view that is gone.
    _release();
    final viewId = await _openNative(window);
    if (viewId == null) {
      return false;
    }

    _window = window;
    _viewId = viewId;
    _sync();
    notifyListeners();
    return true;
  }

  @override
  Future<void> setContentSize(Size contentSize) async {
    if (_window == null) {
      return;
    }

    await _menubar.setPictureWindowSize(contentSize);
  }

  @override
  Future<void> bringToFront() => _menubar.focusPictureWindow();

  @override
  Future<void> startDrag() async {
    if (_window == null) {
      return;
    }

    await _menubar.dragPictureWindow();
  }

  @override
  Future<void> close() async {
    if (_window == null) {
      return;
    }

    await _menubar.closePictureWindow();
  }

  @override
  Future<void> setFullScreen(bool fullScreen) async {
    if (_window == null) {
      return;
    }

    await _menubar.setPictureWindowFullScreen(fullScreen);
  }

  @override
  Future<bool> isFullScreen() async {
    if (_window == null) {
      return false;
    }

    return _menubar.isPictureWindowFullScreen();
  }

  /// Views come and go through the engine, a moment apart from the
  /// plugin's own events, so this is where the window's view really
  /// appears and disappears.
  @override
  void didChangeMetrics() => _sync();

  Future<int?> _openNative(FeatureWindow window) async {
    try {
      return await _menubar.openPictureWindow(
        id: window.id,
        title: window.title,
        size: window.contentSize,
        barHeight: window.barHeight,
        fullScreen: window.fullScreen,
      );
    } on PlatformException {
      return null;
    }
  }

  void _release() {
    if (_window == null) {
      return;
    }

    _window = null;
    _viewId = null;
    _view = null;
    notifyListeners();
  }

  void _forget(int viewId) {
    if (_viewId != viewId) {
      return;
    }

    _release();
  }

  void _sync() {
    final viewId = _viewId;
    if (viewId == null) {
      return;
    }

    final view = _dispatcher.view(id: viewId);
    if (view == _view) {
      return;
    }

    if (view == null) {
      _forget(viewId);
      return;
    }

    _view = view;
    notifyListeners();
  }
}
