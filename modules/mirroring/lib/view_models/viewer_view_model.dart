import 'dart:async';

import 'package:core/core.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mirroring/feature/mirroring_feature.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/services.dart';

/// What the computer's mirror stage, launcher and settings show, and what
/// they can do.
class ViewerViewModel extends ChangeNotifier {
  ViewerViewModel(
    this.feature, {
    MirrorWindow? window,
    Future<String?> Function()? readClipboard,
    ScreenshotStore? screenshots,
    bool? systemMirrors,
    DateTime Function()? clock,
    this.setupInterval = const Duration(seconds: 2),
    this.noticeTime = const Duration(seconds: 10),
    this.slowAfter = const Duration(seconds: 5),
    this.cableHintAfter = const Duration(seconds: 20),
  }) : _window = window ?? MirrorWindow.current(),
       _readClipboard = readClipboard ?? _systemClipboard,
       _screenshots = screenshots ?? ScreenshotStore(),
       _systemMirrors = systemMirrors ?? defaultTargetPlatform == .macOS,
       _clock = clock ?? DateTime.now {
    _subscriptions.add(feature.changes.listen((_) => _onChange()));
  }

  final MirroringFeature feature;

  /// How often the cable steps look whether the phone answered.
  final Duration setupInterval;

  /// How long a line over the picture stays.
  final Duration noticeTime;

  /// How long the picture has to be poor before it is said.
  final Duration slowAfter;

  /// How long no phone has to show up before the cable itself is doubted.
  final Duration cableHintAfter;

  final MirrorWindow _window;
  final Future<String?> Function() _readClipboard;
  final ScreenshotStore _screenshots;

  /// This computer's system already shows an iPhone's screen, as a Mac
  /// does, so Ferret's own receiver is second choice.
  final bool _systemMirrors;
  final DateTime Function() _clock;
  final List<StreamSubscription<void>> _subscriptions = [];

  /// Sessions a device started itself, by the device the open stage asked
  /// for: an iPhone picked from its own page.
  final Map<String, String> _claims = {};

  MirrorViewer? _watched;

  /// Kept between changes, so the widgets that select them only rebuild
  /// when they really are different lists.
  List<MirrorTarget>? _targets;
  List<ReceiverSwitch>? _receivers;
  ToolDownload _download = .idle;
  bool _canFullScreen = false;
  bool _isFullScreen = false;
  bool _disposed = false;

  String? _stageDeviceId;
  PendingShow? _pendingShow;
  MirrorTarget? _pendingTarget;

  String? _cableGuideFor;
  MirrorTarget? _cableGuideTarget;
  DateTime? _cableGuideSince;
  CableSetup? _cableSetup;
  bool _cableUnsupported = false;
  Timer? _setupTimer;

  String? _airplayGuideFor;
  bool _airplayAnyway = false;
  bool _airplayTimedOut = false;
  Timer? _airplayTimer;

  StageNotice? _notice;
  Timer? _noticeTimer;
  String? _noticedSession;
  ViewPhase? _lastPhase;
  DateTime? _poorSince;
  bool _slowTold = false;
  bool _viewOnlyTold = false;
  bool _basicTold = false;
  bool _textFieldOpen = false;
  String? _screenshotPath;

  MirrorViewer? get _viewer => feature.viewer;

  MirrorRoutes? get _routes => feature.routes;

  bool get isAvailable => _viewer != null;

  ViewSession? get current => _viewer?.current;

  MirrorRecord? get lastRecord => _viewer?.lastRecord;

  /// The picture to draw, or null before the first frame.
  MirrorPicture? get picture => _viewer?.picture.value;

  List<MirrorRecord> get history => feature.settings.history;

  /// What this computer is called on other devices' lists.
  String get computerName => feature.host.localDevice.name;

  /// The attempt the stage opened for [deviceId] follows: its own, or the
  /// one a device started itself after being asked for there.
  ViewSession? sessionFor(String deviceId) {
    final current = this.current;
    if (current == null) {
      return null;
    }

    final own =
        current.deviceId == deviceId || _claims[current.deviceId] == deviceId;
    if (!own) {
      return null;
    }

    return current;
  }

  /// Whether the window the stage is in can go full screen at all.
  bool get canFullScreen => _canFullScreen;

  bool get isFullScreen => _isFullScreen;

  /// The app plugged in a way to show a phone on a cable.
  bool get hasCable => _routes?.hasCable ?? false;

  bool get lookForCable => feature.settings.lookForCable;

  Future<void> setLookForCable(bool value) =>
      feature.settings.setLookForCable(value);

  /// The phones on a cable that aren't paired: those get "Show screen" on
  /// their own device.
  List<MirrorTarget> get targets =>
      _targets ??= _routes?.targets ?? const <MirrorTarget>[];

  List<ReceiverSwitch> get receivers =>
      _receivers ??= _routes?.receivers ?? const <ReceiverSwitch>[];

  bool get hasReceivers => _routes?.hasReceivers ?? false;

  /// The devices asking to show their screen here right now.
  List<IncomingRequest> get requests => _routes?.requests ?? const [];

  Future<void> setReceiverOn(String receiverId, bool value) async =>
      _routes?.setReceiverOn(receiverId, value);

  void answer(IncomingRequest request, {required bool allow}) =>
      _routes?.answer(request, allow: allow);

  /// What the device being shown takes from this computer. Empty is view
  /// only.
  Set<ControlAbility> get abilities =>
      _viewer?.control?.abilities ?? const <ControlAbility>{};

  bool get canPress => abilities.contains(ControlAbility.buttons);

  bool get canText => abilities.contains(ControlAbility.text);

  /// Whether the cable could take over from Ferret for [deviceId] right
  /// now, to click and type.
  bool cableOffers(String deviceId) {
    final session = sessionFor(deviceId);
    final routes = _routes;
    if (session == null || routes == null || session.way == .cable) {
      return false;
    }

    return routes.cableTargetFor(deviceId) != null;
  }

  QualityPreset get preset => feature.settings.quality;

  /// Whether a new preset shows at once: only where the picture can be
  /// opened again without asking the device's owner.
  bool get presetRestarts => current?.way == MirrorWay.cable;

  bool get toolbarPinned => feature.settings.toolbarPinned;

  Future<void> setToolbarPinned(bool value) =>
      feature.settings.setToolbarPinned(value);

  bool get textFieldOpen => _textFieldOpen;

  /// The line over the picture right now.
  StageNotice? get notice => _notice;

  /// The folder screenshots go to, as people read it.
  String get screenshotFolder => _screenshots.folderLabel;

  /// The device waiting for a yes before it replaces the one on screen.
  PendingShow? get pendingShow => _pendingShow;

  /// The device whose cable steps are open.
  String? get cableGuideFor => _cableGuideFor;

  /// Where those steps stand. Null until the first look.
  CableSetup? get cableSetup => _cableSetup;

  /// No way to show a phone over a cable works on this computer.
  bool get cableUnsupported => _cableUnsupported;

  /// No phone showed up for a while: time to doubt the cable.
  bool get cableWaitedLong {
    final since = _cableGuideSince;
    return since != null && _clock().difference(since) >= cableHintAfter;
  }

  ToolDownload get download => _download;

  /// The iPhone or iPad whose "pick this computer" steps are open.
  String? get airplayGuideFor => _airplayGuideFor;

  /// Until when this computer listens for it.
  DateTime? get armedUntil => _routes?.armedUntil;

  /// The system does this already, and the person hasn't said to use
  /// Ferret anyway.
  bool get airplayDefersToSystem => _systemMirrors && !_airplayAnyway;

  bool get airplayTimedOut => _airplayTimedOut;

  /// Shows the paired device [deviceId] the best way there is. With
  /// another device on screen, that one is asked about first.
  Future<void> show(String deviceId, String deviceName) async {
    if (_replaces(deviceId)) {
      _pendingTarget = null;
      _pendingShow = PendingShow(deviceId: deviceId, deviceName: deviceName);
      _notify();
      return;
    }

    await _showNow(deviceId);
  }

  /// Shows a phone on a cable that isn't paired.
  Future<void> showTarget(MirrorTarget target) async {
    final deviceId = ViewSession.deviceIdOf(target);
    if (_replaces(deviceId)) {
      _pendingTarget = target;
      _pendingShow = PendingShow(deviceId: deviceId, deviceName: target.name);
      _notify();
      return;
    }

    await _startTarget(target);
  }

  Future<void> confirmReplace() async {
    final pending = _pendingShow;
    final target = _pendingTarget;
    _pendingShow = null;
    _pendingTarget = null;
    _notify();
    if (pending == null) {
      return;
    }

    if (target != null) {
      await _startTarget(target);
      return;
    }

    await _showNow(pending.deviceId);
  }

  void cancelReplace() {
    _pendingShow = null;
    _pendingTarget = null;
    _notify();
  }

  /// Asks or shows again after the attempt for [deviceId] ended.
  Future<void> again(String deviceId) async {
    final session = sessionFor(deviceId);
    if (session == null || session.target.ferretDeviceId != null) {
      await _showNow(deviceId);
      return;
    }

    if (session.way == .airplay) {
      _viewer?.dismiss();
      await openAirplayGuide(deviceId);
      return;
    }

    await _startTarget(session.target);
  }

  /// Shows [deviceId] over the cable instead, to click and type.
  Future<void> controlWithCable(String deviceId) async {
    _watch();
    await _viewer?.show(deviceId, preferControl: true);
  }

  /// Opens the cable steps for [deviceId]. They tick themselves, and the
  /// picture starts once the phone answers. Looking for phones on a cable
  /// turns on with it.
  void openCableGuide(String deviceId, {MirrorTarget? target}) {
    if (_cableGuideFor == deviceId) {
      return;
    }

    _closeCableGuide();
    _cableGuideFor = deviceId;
    _cableGuideTarget = target;
    _cableGuideSince = _clock();
    if (!lookForCable) {
      unawaited(setLookForCable(true));
    }

    _setupTimer = .periodic(setupInterval, (_) => unawaited(_checkSetup()));
    unawaited(_checkSetup());
    _notify();
  }

  void closeCableGuide() {
    _closeCableGuide();
    _notify();
  }

  /// Downloads the tool the cable needs. Only from the button whose words
  /// say what is downloaded and from where.
  Future<void> downloadTool() async {
    if (_download == .downloading) {
      return;
    }

    _setDownload(.downloading);
    try {
      await _routes?.installTool();
      _setDownload(.idle);
      await _checkSetup();
    } on Object catch (error) {
      printWarning('Downloading the tool for the cable failed', error);
      _setDownload(.failed);
    }
  }

  /// Opens the steps for the iPhone or iPad [deviceId], and listens for
  /// it for a moment unless the system does this already.
  Future<void> openAirplayGuide(String deviceId) async {
    _airplayGuideFor = deviceId;
    _airplayTimedOut = false;
    _notify();
    if (airplayDefersToSystem) {
      return;
    }

    await _listenForAirplay();
  }

  Future<void> useFerretAnyway() async {
    _airplayAnyway = true;
    await _listenForAirplay();
  }

  Future<void> listenAgain() async {
    _airplayTimedOut = false;
    await _listenForAirplay();
  }

  void perform(InputAction action) {
    final control = _viewer?.control;
    switch (action) {
      case SendPointer(:final pointer):
        control?.pointer(pointer);
      case SendKey(:final key):
        control?.key(key);
      case SendText(:final text):
        control?.text(text);
      case PasteText(:final text):
        control?.setClipboard(text, paste: true);
      case PasteClipboard():
        unawaited(paste());
      case PressButton(:final button):
        control?.press(button);
      case OpenTextField():
        openTextField();
      case TakeScreenshot():
        unawaited(screenshot());
      case NoInput():
        return;
    }
  }

  void press(DeviceButton button) => _viewer?.control?.press(button);

  /// Pastes this computer's clipboard on the device.
  Future<void> paste() async {
    final text = await _readClipboard();
    if (text == null || text.isEmpty) {
      return;
    }

    _viewer?.control?.setClipboard(text, paste: true);
  }

  /// Saves the picture as it is right now to a file, and says where it
  /// went.
  Future<void> screenshot() async {
    final viewer = _viewer;
    final session = current;
    if (viewer == null || session == null || picture == null) {
      return;
    }

    final path = _screenshots.pathFor(session.deviceName, _clock());
    final saved = await viewer.savePicture(path);
    if (!saved) {
      _screenshotPath = null;
      _showNotice(.screenshotFailed);
      return;
    }

    _screenshotPath = path;
    _showNotice(.screenshotSaved);
  }

  /// Shows the last screenshot in its folder.
  Future<void> revealScreenshot() async {
    final path = _screenshotPath;
    if (path == null) {
      return;
    }

    dismissNotice();
    try {
      await _screenshots.reveal(path);
    } on Object catch (error) {
      printWarning('Showing the screenshot in its folder failed', error);
    }
  }

  void openTextField() {
    if (!canText || _textFieldOpen) {
      return;
    }

    _textFieldOpen = true;
    _notify();
  }

  void closeTextField() {
    if (!_textFieldOpen) {
      return;
    }

    _textFieldOpen = false;
    _notify();
  }

  /// Sends text composed in the field, accents and emoji included.
  void sendComposed(String text) {
    if (text.isEmpty) {
      return;
    }

    perform(MirrorKeys.textAction(text, abilities));
  }

  /// A click on a picture that can only be looked at: said once.
  void noteViewOnlyTap() {
    if (_viewOnlyTold) {
      return;
    }

    _viewOnlyTold = true;
    _showNotice(.viewOnly);
  }

  void dismissNotice() {
    _noticeTimer?.cancel();
    _noticeTimer = null;
    if (_notice == null) {
      return;
    }

    _notice = null;
    _notify();
  }

  Future<void> setPreset(QualityPreset preset) async {
    await feature.settings.setQuality(preset);
    if (_notice == .slow) {
      dismissNotice();
    }

    _notify();
    await _viewer?.restart();
  }

  Future<void> stop() async {
    await _viewer?.stop();
    await setFullScreen(false);
  }

  /// The device whose stage is on screen.
  String? get stageDeviceId => _stageDeviceId;

  /// The stage for [deviceId] is on screen. A stage says so while it is
  /// being built, so listeners hear it right after.
  void openStage(String deviceId) {
    if (_stageDeviceId == deviceId) {
      return;
    }

    _stageDeviceId = deviceId;
    scheduleMicrotask(_notify);
  }

  /// The stage for [deviceId] closed: sharing stops with it, and what it
  /// was in the middle of is let go. A stage another one took over from
  /// leaves everything alone.
  Future<void> leaveStage(String deviceId) async {
    if (_stageDeviceId != deviceId) {
      return;
    }

    _stageDeviceId = null;
    _pendingShow = null;
    _pendingTarget = null;
    _textFieldOpen = false;
    _closeCableGuide();
    await _closeAirplayGuide();
    dismissNotice();
    _notify();
    if (sessionFor(deviceId) == null) {
      return;
    }

    await stop();
    _viewer?.dismiss();
  }

  void dismissRecord() => _viewer?.dismissRecord();

  Future<void> clearHistory() async => _viewer?.clearHistory();

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
    _setupTimer?.cancel();
    _airplayTimer?.cancel();
    _noticeTimer?.cancel();
    _watched?.picture.removeListener(_notify);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }

  static Future<String?> _systemClipboard() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  /// Whether showing [deviceId] would take the place of another device
  /// that is asked or shown right now.
  bool _replaces(String deviceId) =>
      (current?.isLive ?? false) && sessionFor(deviceId) == null;

  Future<void> _showNow(String deviceId) async {
    _watch();
    unawaited(refreshWindow());
    _closeCableGuide();
    await _viewer?.show(deviceId);
  }

  Future<void> _startTarget(MirrorTarget target) async {
    _watch();
    unawaited(refreshWindow());
    _closeCableGuide();
    await _viewer?.startTarget(target);
  }

  void _closeCableGuide() {
    _setupTimer?.cancel();
    _setupTimer = null;
    _cableGuideFor = null;
    _cableGuideTarget = null;
    _cableGuideSince = null;
    _cableSetup = null;
  }

  /// Looks where the cable stands, and starts the picture the moment the
  /// phone is ready: no button to press.
  Future<void> _checkSetup() async {
    final deviceId = _cableGuideFor;
    final routes = _routes;
    if (deviceId == null || routes == null) {
      return;
    }

    final setup = await routes.cableSetup();
    if (_cableGuideFor != deviceId || _disposed) {
      return;
    }

    _cableUnsupported = setup == null;
    _cableSetup = setup;
    final target =
        _cableGuideTarget ?? routes.cableTargetFor(deviceId, orOnlyOne: true);
    final ready = setup != null && setup.isReady && target != null;
    if (!ready || !routes.isReachable(target)) {
      _notify();
      return;
    }

    await _startTarget(target);
  }

  Future<void> _listenForAirplay() async {
    _airplayTimer?.cancel();
    await _routes?.armReceivers();
    final until = armedUntil;
    if (until != null) {
      _airplayTimer = Timer(until.difference(_clock()), _onAirplayTimeout);
    }

    _notify();
  }

  void _onAirplayTimeout() {
    if (_airplayGuideFor == null) {
      return;
    }

    _airplayTimedOut = true;
    _notify();
  }

  Future<void> _closeAirplayGuide() async {
    _airplayTimer?.cancel();
    _airplayTimer = null;
    if (_airplayGuideFor == null) {
      return;
    }

    _airplayGuideFor = null;
    _airplayTimedOut = false;
    await _routes?.disarmReceivers();
  }

  void _setDownload(ToolDownload state) {
    _download = state;
    _notify();
  }

  void _showNotice(StageNotice notice, {bool stays = false}) {
    _noticeTimer?.cancel();
    _noticeTimer = null;
    _notice = notice;
    if (!stays) {
      _noticeTimer = Timer(noticeTime, dismissNotice);
    }

    _notify();
  }

  void _onChange() {
    _watch();
    _targets = null;
    _receivers = null;
    _claimIncoming();
    _followSession();
    _startWhenBack();
    _notify();
  }

  /// A device that starts by itself while its steps are open belongs to
  /// that stage.
  void _claimIncoming() {
    final guideFor = _airplayGuideFor;
    final current = this.current;
    final started =
        current != null && current.isLive && current.way == .airplay;
    if (guideFor == null || current == null || !started) {
      return;
    }

    _claims
      ..clear()
      ..[current.deviceId] = guideFor;
    _airplayTimer?.cancel();
    _airplayTimer = null;
    _airplayGuideFor = null;
  }

  /// What each new picture has to say once, and the cable steps for a
  /// phone that turned out not to be ready.
  void _followSession() {
    final current = this.current;
    final phase = current?.phase;
    final sessionKey = current?.deviceId;
    if (sessionKey != _noticedSession) {
      _noticedSession = sessionKey;
      _slowTold = false;
      _viewOnlyTold = false;
      _poorSince = null;
      _textFieldOpen = false;
    }

    final began = phase == .streaming && _lastPhase != .streaming;
    _lastPhase = phase;
    if (current == null) {
      return;
    }

    if (current.end == .needsSetup && _stageDeviceId == current.deviceId) {
      openCableGuide(current.deviceId, target: current.target);
      return;
    }

    if (began) {
      _noticeFor(current);
    }
  }

  void _noticeFor(ViewSession session) {
    final overCable = session.way == .cable;
    final told = feature.settings.cableTold.contains(session.target.id);
    if (overCable && !told) {
      unawaited(feature.settings.addCableTold(session.target.id));
      _showNotice(.cableNoAsk);
      return;
    }

    if (session.viaFallback) {
      _showNotice(.viaCable);
      return;
    }

    if (session.config?.codec == .jpeg && !_basicTold) {
      _basicTold = true;
      _showNotice(.basicPicture);
    }
  }

  /// A paired phone that wasn't connected starts by itself the moment it
  /// is, while its stage is still open.
  void _startWhenBack() {
    final deviceId = _stageDeviceId;
    final routes = _routes;
    if (deviceId == null || routes == null || _cableGuideFor != null) {
      return;
    }

    final session = sessionFor(deviceId);
    final waits =
        session != null &&
        session.end == .notConnected &&
        session.target.ferretDeviceId != null;
    if (!waits || !routes.isReachable(routes.bestTargetFor(deviceId))) {
      return;
    }

    unawaited(_showNow(deviceId));
  }

  void _onStats() {
    final current = this.current;
    final isPoor =
        current != null &&
        current.phase == .streaming &&
        current.stats.quality == .poor;
    if (!isPoor) {
      _poorSince = null;
      if (_notice == .slow) {
        dismissNotice();
        return;
      }

      _notify();
      return;
    }

    final since = _poorSince ??= _clock();
    if (!_slowTold && _clock().difference(since) >= slowAfter) {
      _slowTold = true;
      _showNotice(.slow, stays: true);
      return;
    }

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
    _subscriptions.add(viewer.statsChanges.listen((_) => _onStats()));
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
