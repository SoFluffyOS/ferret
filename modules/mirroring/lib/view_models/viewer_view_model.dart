import 'dart:async';

import 'package:core/core.dart';
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

  /// Kept between changes, so the widgets that select them only rebuild
  /// when they really are different lists.
  List<MirrorTarget>? _targets;
  List<RouteNotice>? _notices;
  List<ReceiverSwitch>? _receivers;
  Map<String, ToolDownload> _downloads = const {};
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

  bool get hasCard =>
      (current?.isLive ?? false) || lastRecord != null || targets.isNotEmpty;

  /// The app plugged in more ways to show a screen than Ferret's own.
  bool get hasMoreWays => feature.routes?.hasMoreWays ?? false;

  /// Those ways are turned on. Off until the owner asks for them.
  bool get moreWays => feature.routes?.moreWaysOn ?? false;

  /// The screens the other ways found, apart from paired devices: those
  /// get "Show screen" on their own page.
  List<MirrorTarget> get targets => _targets ??= [
    for (final target in feature.routes?.targets ?? const <MirrorTarget>[])
      if (!_isPaired(target)) target,
  ];

  /// What the other ways still need before they work on this computer.
  List<RouteNotice> get notices =>
      _notices ??= feature.routes?.notices ?? const [];

  /// How each route's tool download goes, by route id. A route that isn't
  /// listed is [ToolDownload.idle].
  Map<String, ToolDownload> get downloads => _downloads;

  /// Downloads the tool the route [routeId] is missing. Only from the
  /// button whose words say what is downloaded and from where.
  Future<void> downloadTool(String routeId) async {
    if (_downloads[routeId] == .downloading) {
      return;
    }

    _setDownload(routeId, .downloading);
    try {
      await feature.routes?.installTool(routeId);
      _setDownload(routeId, .idle);
    } on Object catch (error) {
      printWarning('Downloading the tool for $routeId failed', error);
      _setDownload(routeId, .failed);
    }
  }

  /// The receivers to switch on or off, while the other ways are on.
  List<ReceiverSwitch> get receivers => _receivers ??= switch (moreWays) {
    true => feature.routes?.receivers ?? const [],
    false => const [],
  };

  /// The devices asking to show their screen here right now.
  List<IncomingRequest> get requests => feature.routes?.requests ?? const [];

  Future<void> setReceiverOn(String receiverId, bool value) async =>
      feature.routes?.setReceiverOn(receiverId, value);

  void answer(IncomingRequest request, {required bool allow}) =>
      feature.routes?.answer(request, allow: allow);

  /// Whether clicks and scrolling reach the device being shown.
  bool get canPoint => _abilities.contains(ControlAbility.pointer);

  /// Whether typing reaches the device being shown.
  bool get canType => _abilities.contains(ControlAbility.keys);

  /// The device's own buttons this computer can press for it.
  List<DeviceButton> get deviceButtons {
    if (!_abilities.contains(ControlAbility.buttons)) {
      return const [];
    }

    return const [.back, .home, .recents];
  }

  /// Another way to show the paired device [deviceId] when Ferret's own
  /// connection can't.
  MirrorTarget? targetForDevice(String deviceId) =>
      feature.routes?.targetForDevice(deviceId);

  Future<void> start(String deviceId) async {
    _watch();
    unawaited(refreshWindow());
    await _viewer?.start(deviceId);
  }

  Future<void> startTarget(MirrorTarget target) async {
    _watch();
    unawaited(refreshWindow());
    await _viewer?.startTarget(target);
  }

  /// Asks again the same way as the attempt that just ended.
  Future<void> retry(String deviceId) async {
    final current = this.current;
    if (current == null || current.deviceId != deviceId) {
      await start(deviceId);
      return;
    }

    await startTarget(current.target);
  }

  Future<void> setMoreWays(bool value) => feature.settings.setMoreWays(value);

  /// Asks the other ways again where they stand, after a setup step.
  Future<void> checkRoutes() async => feature.routes?.refresh();

  void sendPointer(MirrorPointer event) => _viewer?.control?.pointer(event);

  void sendKey(MirrorKey event) => _viewer?.control?.key(event);

  void press(DeviceButton button) => _viewer?.control?.press(button);

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

  Set<ControlAbility> get _abilities => _viewer?.control?.abilities ?? const {};

  void _setDownload(String routeId, ToolDownload state) {
    _downloads = {..._downloads, routeId: state};
    _notify();
  }

  bool _isPaired(MirrorTarget target) {
    final deviceId = target.ferretDeviceId;
    return deviceId != null && feature.host.trustStore[deviceId] != null;
  }

  void _onChange() {
    _watch();
    _targets = null;
    _notices = null;
    _receivers = null;
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
