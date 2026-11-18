import 'dart:async';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/foundation.dart';
import 'package:mirroring/feature/mirroring_feature.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/services.dart';

/// What the computer's mirror page, card and settings show, and what they
/// can do.
class ViewerViewModel extends ChangeNotifier {
  ViewerViewModel(this.feature, {MirrorWindow? window})
    : _window = window ?? MirrorWindow.current() {
    _subscriptions.add(feature.changes.listen((_) => _onChange()));
  }

  final MirroringFeature feature;
  final MirrorWindow _window;
  final List<StreamSubscription<void>> _subscriptions = [];

  MirrorViewer? _watched;
  bool _canFullScreen = false;
  bool _isFullScreen = false;
  bool _disposed = false;

  MirrorViewer? get _viewer => feature.viewer;

  bool get isAvailable => _viewer != null;

  ViewSession? get current => _viewer?.current;

  MirrorRecord? get lastRecord => _viewer?.lastRecord;

  /// The picture to draw, or null before the first frame.
  MirrorPicture? get picture => _viewer?.picture.value;

  bool get actualSize => feature.settings.actualSize;

  List<MirrorRecord> get history => feature.settings.history;

  /// Whether the window the page is in can go full screen at all.
  bool get canFullScreen => _canFullScreen;

  bool get isFullScreen => _isFullScreen;

  bool get hasCard => (current?.isLive ?? false) || lastRecord != null;

  Future<void> start(String deviceId) async {
    _watch();
    unawaited(refreshWindow());
    await _viewer?.start(deviceId);
  }

  Future<void> stop() async {
    await _viewer?.stop();
    await setFullScreen(false);
  }

  /// The mirror page closed: an attempt that is over is forgotten; one
  /// that still runs stays on the home card.
  Future<void> leavePage() async {
    await setFullScreen(false);
    _viewer?.dismiss();
  }

  void dismissRecord() => _viewer?.dismissRecord();

  Future<void> clearHistory() async => _viewer?.clearHistory();

  Future<void> setActualSize(bool value) =>
      feature.settings.setActualSize(value);

  Future<void> refreshWindow() async {
    _canFullScreen = await _window.canFullScreen();
    _isFullScreen = _canFullScreen && await _window.isFullScreen();
    _notify();
  }

  Future<void> setFullScreen(bool fullScreen) async {
    if (!_canFullScreen || _isFullScreen == fullScreen) {
      return;
    }

    await _window.setFullScreen(fullScreen);
    _isFullScreen = fullScreen;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _watched?.picture.removeListener(_notify);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }

  void _onChange() {
    _watch();
    _notify();
  }

  /// The viewer exists once the engine started; its numbers and picture
  /// change far more often than the rest.
  void _watch() {
    final viewer = _viewer;
    if (viewer == null || identical(viewer, _watched)) {
      return;
    }

    _watched = viewer;
    viewer.picture.addListener(_notify);
    _subscriptions.add(viewer.statsChanges.listen((_) => _notify()));
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
