import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/view_models/viewer_view_model.dart';

/// The mirror stage's own window, where this computer has one to give:
/// which device's stage is in it, and the shape it keeps. The window is
/// the picture with a bar on top: it takes the picture's shape, and turns
/// when the phone does.
class StageWindowViewModel extends ChangeNotifier {
  StageWindowViewModel(this._viewer);

  /// A phone held upright, until its first picture says what it really is.
  static const firstShape = Size(1080, 2340);

  /// A camera's picture as a phone on its side sends it.
  static const cameraShape = Size(1280, 720);

  /// A laptop's screen, until the computer lending its display says.
  static const displayShape = Size(2560, 1600);

  final ViewerViewModel _viewer;
  FeatureWindows? _windows;
  String? _deviceId;
  Size? _shape;
  bool _opening = false;
  bool _disposed = false;
  bool _fullScreen = false;

  /// Whether the window fills its screen, as far as this side put it so.
  bool get isFullScreen => _fullScreen;

  /// Whether Show screen opens a window of its own here.
  bool get canOpen => _windows?.canOpen ?? false;

  /// The device whose stage is in the window, from the moment it is asked
  /// for.
  String? get deviceId => _deviceId;

  /// Gives the windows the app has for features. Without, the stage stays
  /// in a page or a pane.
  void attach(FeatureWindows? windows) {
    _windows?.removeListener(_onWindows);
    _windows = windows;
    windows?.addListener(_onWindows);
    _viewer.addListener(_onViewer);
    _notify();
  }

  /// Opens the window for [deviceId] with [builder] in it, in place of
  /// the one that is open, or brings it to the front. False when there is
  /// no window to open.
  Future<bool> open({
    required String deviceId,
    required String title,
    required WidgetBuilder builder,
    double barHeight = 0,
    Size shape = firstShape,
    bool fullScreen = false,
  }) async {
    final windows = _windows;
    if (windows == null || !windows.canOpen) {
      return false;
    }

    final content = _pictureOf(deviceId) ?? shape;
    _deviceId = deviceId;
    _shape = content;
    _opening = true;
    _notify();
    final opened = await windows.open(
      FeatureWindow(
        id: _windowId(deviceId),
        title: title,
        contentSize: content,
        barHeight: barHeight,
        builder: builder,
        fullScreen: fullScreen,
      ),
    );
    _opening = false;
    _fullScreen = opened && fullScreen;
    if (!opened && _deviceId == deviceId) {
      _deviceId = null;
      _shape = null;
      _notify();
    }

    return opened;
  }

  Future<void> bringToFront() async => _windows?.bringToFront();

  /// Moves the window with the pointer, from a press on its bar.
  Future<void> startDrag() async => _windows?.startDrag();

  /// Closes the window, which stops what it showed.
  Future<void> close() async => _windows?.close();

  /// Puts the window in full screen, or takes it out.
  Future<void> setFullScreen(bool fullScreen) async {
    final windows = _windows;
    if (windows == null) {
      return;
    }

    await windows.setFullScreen(fullScreen);
    _fullScreen = fullScreen;
    _notify();
  }

  /// Full screen when it isn't, and back. Asks the window, which may have
  /// left full screen its own way.
  Future<void> toggleFullScreen() async {
    final windows = _windows;
    if (windows == null) {
      return;
    }

    await setFullScreen(!await windows.isFullScreen());
  }

  @override
  void dispose() {
    _disposed = true;
    _windows?.removeListener(_onWindows);
    _viewer.removeListener(_onViewer);
    super.dispose();
  }

  static String _windowId(String deviceId) => 'mirroring.$deviceId';

  /// The size of the picture [deviceId] shows right now.
  Size? _pictureOf(String deviceId) {
    final picture = _viewer.picture;
    if (picture == null || _viewer.sessionFor(deviceId) == null) {
      return null;
    }

    return Size(picture.width.toDouble(), picture.height.toDouble());
  }

  void _onViewer() {
    final deviceId = _deviceId;
    if (deviceId == null) {
      return;
    }

    final shape = _pictureOf(deviceId);
    if (shape == null || shape == _shape) {
      return;
    }

    _shape = shape;
    unawaited(_windows?.setContentSize(shape));
  }

  /// The window closed, or another feature's took its place. While it is
  /// opening, the one it replaces closing is no news.
  void _onWindows() {
    final deviceId = _deviceId;
    final isOpen = _windows?.openId == _windowId(deviceId ?? '');
    if (deviceId == null || _opening || isOpen) {
      return;
    }

    _deviceId = null;
    _shape = null;
    _fullScreen = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
