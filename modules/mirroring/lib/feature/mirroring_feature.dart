import 'dart:async';
import 'dart:io' as io;

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart' as remote;
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';
import 'package:protocol/protocol.dart';

/// See an Android phone's screen on a computer. The computer asks; the
/// phone's owner answers Android's own prompt every time, sees an ongoing
/// "Sharing screen" notice with Stop, and both sides keep an audit line.
/// The other way round, a Mac lends its desktop to another computer as an
/// extra display, after that computer's owner said yes.
class MirroringFeature extends Feature {
  MirroringFeature({
    ScreenCapture Function()? capture,
    CameraCapture Function()? camera,
    PhoneControl Function()? phoneControl,
    DisplayCapture Function()? display,
    remote.InputInjector Function()? injector,
    MirrorDecoder Function()? decoder,
    List<MirrorCodec>? codecs,
    AudioSink Function()? audioSink,
    List<MirrorAudioCodec>? audioCodecs,
    List<MirrorRoute> routes = const [],
    List<MirrorReceiver> receivers = const [],
    bool? canShare,
    bool? canShareCamera,
    bool? canView,
    bool? canExtend,
    bool? canBeDisplay,
    ConsentTexts Function(String deviceName, {bool withSound})? texts,
    CameraTexts Function(String deviceName, {bool withSound})? cameraTexts,
    DateTime Function()? clock,
    this.consentTimeout = const Duration(seconds: 60),
    this.requestTimeout = const Duration(seconds: 10),
    this.firstPictureTimeout = const Duration(seconds: 10),
  }) : _createCapture = capture ?? ScreenCapture.current,
       _createCamera = camera ?? CameraCapture.current,
       _createPhoneControl = phoneControl ?? PhoneControl.new,
       _createDisplay = display ?? DisplayCapture.current,
       _createInjector = injector ?? remote.InputInjector.current,
       _createDecoder = decoder ?? MirrorDecoder.current,
       _codecs = codecs,
       _createAudioSink = audioSink,
       _audioCodecs = audioCodecs,
       _extraRoutes = routes,
       _receivers = receivers,
       canShare = canShare ?? ScreenCapture.isSupportedPlatform,
       canShareCamera = canShareCamera ?? CameraCapture.isSupportedPlatform,
       canView =
           canView ??
           (io.Platform.isMacOS ||
               io.Platform.isWindows ||
               io.Platform.isLinux),
       canExtend = canExtend ?? DisplayCapture.isSupportedPlatform,
       canBeDisplay =
           canBeDisplay ??
           (io.Platform.isMacOS &&
               (codecs ?? MirrorDecoder.platformCodecs).contains(
                 MirrorCodec.h264,
               )),
       _clock = clock ?? DateTime.now {
    if (texts != null) {
      this.texts = texts;
    }

    if (cameraTexts != null) {
      this.cameraTexts = cameraTexts;
    }
  }

  static const featureId = 'mirroring';

  /// Flag in [FeatureSupport]: this device can show its screen.
  static const shareFlag = MirrorProtocol.shareFlag;

  /// Flag in [FeatureSupport]: this device can show another's screen.
  static const viewFlag = MirrorProtocol.viewFlag;

  /// Flag in [FeatureSupport]: this device can send its camera and
  /// microphone.
  static const cameraFlag = MirrorProtocol.cameraFlag;

  /// This device's screen can be captured: Android phones and tablets.
  final bool canShare;

  /// This device's camera can be sent: Android phones and tablets.
  final bool canShareCamera;

  /// This device shows other screens: computers.
  final bool canView;

  /// This computer can lend its desktop to another device as an extra
  /// display: a Mac, for now.
  final bool canExtend;

  /// This device can be another computer's extra display: it decodes
  /// H.264 and has a screen to fill. A Mac, for now.
  final bool canBeDisplay;

  final Duration consentTimeout;
  final Duration requestTimeout;
  final Duration firstPictureTimeout;

  /// The words on the phone's own notices. The app sets them in the
  /// owner's language before any request can arrive.
  ConsentTexts Function(String deviceName, {bool withSound}) texts =
      _plainTexts;

  /// The words on the phone's ongoing notice while its camera is on.
  CameraTexts Function(String deviceName, {bool withSound}) cameraTexts =
      _plainCameraTexts;

  final ScreenCapture Function() _createCapture;
  final CameraCapture Function() _createCamera;
  final PhoneControl Function() _createPhoneControl;
  final DisplayCapture Function() _createDisplay;
  final remote.InputInjector Function() _createInjector;
  final MirrorDecoder Function() _createDecoder;
  final List<MirrorCodec>? _codecs;
  final AudioSink Function()? _createAudioSink;
  final List<MirrorAudioCodec>? _audioCodecs;
  final List<MirrorRoute> _extraRoutes;
  final List<MirrorReceiver> _receivers;
  final DateTime Function() _clock;
  final StreamController<void> _changes = .broadcast();
  final List<StreamSubscription<void>> _subscriptions = [];

  MirrorSource? _source;
  CameraSource? _camera;
  MirrorViewer? _viewer;
  MirrorRoutes? _routes;
  DisplaySource? _display;
  DisplayCapture? _displayCapture;

  @override
  String get id => featureId;

  @override
  List<String> get flags => [
    if (canShare) shareFlag,
    if (canShareCamera) cameraFlag,
    if (canView) viewFlag,
    if (canExtend) MirrorProtocol.extendFlag,
    if (canView && canBeDisplay) MirrorProtocol.displayFlag,
  ];

  MirroringSettings get settings => MirroringSettings(host.settings);

  /// The phone's side, or null on computers.
  MirrorSource? get source => _source;

  /// The phone's side of "use this phone's camera", or null on computers
  /// and iPhones.
  CameraSource? get camera => _camera;

  /// The computer's side, or null on phones.
  MirrorViewer? get viewer => _viewer;

  /// This computer's side of lending its desktop as another device's
  /// display, or null where it can't.
  DisplaySource? get display => _display;

  /// Every way a screen can arrive here, or null on phones: Ferret's own
  /// route, and the routes and receivers the app plugged in.
  MirrorRoutes? get routes => _routes;

  /// Fires when anything the cards, health or settings show may have
  /// changed. The picture's numbers come from the viewer instead.
  Stream<void> get changes => _changes.stream;

  /// Whether [session]'s device can show its screen here.
  bool canViewDevice(Session session) =>
      canView && (_routes?.ferret.canShow(session) ?? false);

  /// Whether [session]'s device can send its camera here.
  bool canUseCameraOf(Session session) =>
      canView && (_routes?.ferret.canSendCamera(session) ?? false);

  /// Whether this computer can lend its desktop to [session]'s device.
  bool canExtendTo(Session session) => _display?.canExtendTo(session) ?? false;

  @override
  Future<void> onStart() async {
    if (canShare) {
      final source = MirrorSource(
        host: host,
        featureId: featureId,
        capture: _createCapture(),
        phoneControl: _createPhoneControl(),
        settings: settings,
        texts: (deviceName, {withSound = false}) =>
            texts(deviceName, withSound: withSound),
        isBusy: () => _camera?.isBusy ?? false,
        clock: _clock,
        consentTimeout: consentTimeout,
      );
      _source = source;
      _subscriptions.add(source.changes.listen((_) => _emit()));
      await source.start();
    }

    if (canShareCamera) {
      final camera = CameraSource(
        host: host,
        featureId: featureId,
        capture: _createCamera(),
        settings: settings,
        texts: (deviceName, {withSound = false}) =>
            cameraTexts(deviceName, withSound: withSound),
        isBusy: () => _source?.active != null || _source?.pending != null,
        clock: _clock,
        askTimeout: consentTimeout,
      );
      _camera = camera;
      _subscriptions.add(camera.changes.listen((_) => _emit()));
      await camera.start();
    }

    final capture = switch (canExtend || canBeDisplay) {
      true => _createDisplay(),
      false => null,
    };
    _displayCapture = capture;
    if (canExtend && capture != null) {
      final display = DisplaySource(
        host: host,
        featureId: featureId,
        capture: capture,
        injector: _createInjector(),
        clock: _clock,
        offerTimeout: requestTimeout,
      );
      _display = display;
      _subscriptions.add(display.changes.listen((_) => _emit()));
      await display.start();
    }

    if (canView) {
      final routes = MirrorRoutes(
        ferret: FerretRoute(
          host: host,
          featureId: featureId,
          clock: _clock,
          panel: _ownScreen,
          requestTimeout: requestTimeout,
        ),
        settings: settings,
        receiverName: () => host.localDevice.name,
        pairedPhones: _pairedPhones,
        clock: _clock,
        routes: _extraRoutes,
        receivers: _receivers,
      );
      final viewer = MirrorViewer(
        routes: routes,
        createDecoder: _createDecoder,
        codecs: _codecs ?? MirrorDecoder.platformCodecs,
        settings: settings,
        createAudioSink: _createAudioSink,
        audioCodecs: _audioCodecs,
        clock: _clock,
        firstPictureTimeout: firstPictureTimeout,
      );
      routes.isShowingIncoming = () => viewer.isShowingIncoming;
      _routes = routes;
      _viewer = viewer;
      _subscriptions
        ..add(viewer.changes.listen((_) => _emit()))
        ..add(routes.changes.listen((_) => _emit()))
        ..add(
          routes.incoming.listen(
            (feed) => unawaited(viewer.showIncoming(feed)),
          ),
        );
      routes.start();
    }

    _subscriptions.add(settings.changes.listen((_) => _emit()));
  }

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await _source?.dispose();
    await _camera?.dispose();
    await _viewer?.dispose();
    await _routes?.dispose();
    final display = _display;
    if (display != null) {
      await display.dispose();
      return;
    }

    await _displayCapture?.dispose();
  }

  @override
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    unawaited(_source?.onSessionClosed(deviceId));
    unawaited(_camera?.onSessionClosed(deviceId));
    unawaited(_display?.onSessionClosed(deviceId));
    _routes?.ferret.onSessionClosed(deviceId);
    _routes?.withdrawDisplay(deviceId);
  }

  @override
  Future<GeneratedMessage?> onEnvelope(
    Session session,
    Envelope envelope,
  ) async {
    if (payloadOf(envelope, Frame.new) case final frame?) {
      _routes?.ferret.onFrame(session, frame);
      return null;
    }

    if (payloadOf(envelope, AudioFrame.new) case final frame?) {
      _routes?.ferret.onAudioFrame(session, frame);
      return null;
    }

    if (payloadOf(envelope, ControlInput.new) case final input?) {
      _source?.control?.onInput(session.remoteDeviceId, input);
      await _display?.onInput(session.remoteDeviceId, input);
      return null;
    }

    if (payloadOf(envelope, DisplayOffer.new) case final offer?) {
      return _onDisplayOffer(session, offer);
    }

    if (payloadOf(envelope, DisplayDecline.new) case final decline?) {
      _display?.onDecline(session, decline);
      return null;
    }

    if (payloadOf(envelope, ControlState.new) case final state?) {
      _routes?.ferret.onControlState(session, state);
      return null;
    }

    if (payloadOf(envelope, ControlAsk.new) != null) {
      await _source?.control?.onAsk(session.remoteDeviceId);
      return null;
    }

    if (payloadOf(envelope, ControlRelease.new) != null) {
      await _source?.control?.onRelease(session.remoteDeviceId);
      return null;
    }

    if (payloadOf(envelope, StartRequest.new) case final request?) {
      return _onRequest(session, request);
    }

    if (payloadOf(envelope, CameraState.new) case final state?) {
      _routes?.ferret.onCameraState(session, state);
      return null;
    }

    if (payloadOf(envelope, CameraSwitch.new) case final change?) {
      await _camera?.onSwitch(session, change);
      return null;
    }

    if (payloadOf(envelope, StreamConfig.new) case final config?) {
      _routes?.ferret.onConfig(session, config);
      return null;
    }

    if (payloadOf(envelope, AudioConfig.new) case final config?) {
      _routes?.ferret.onAudioConfig(session, config);
      return null;
    }

    if (payloadOf(envelope, AudioEnded.new) != null) {
      _routes?.ferret.onAudioEnded(session);
      return null;
    }

    if (payloadOf(envelope, Stats.new) case final stats?) {
      await _source?.onStats(session, stats);
      await _camera?.onStats(session, stats);
      await _display?.onStats(session, stats);
      _routes?.ferret.onStats(session, stats);
      return null;
    }

    if (payloadOf(envelope, KeyframeRequest.new) != null) {
      await _source?.onKeyframeRequest(session);
      await _camera?.onKeyframeRequest(session);
      await _display?.onKeyframeRequest(session);
      return null;
    }

    if (payloadOf(envelope, SourceState.new) case final state?) {
      _routes?.ferret.onSourceState(session, state);
      return null;
    }

    if (payloadOf(envelope, Stop.new) case final stop?) {
      await _source?.onStop(session);
      await _camera?.onStop(session);
      await _display?.onStop(session);
      _routes?.ferret.onStop(session, stop);
      _routes?.withdrawDisplay(session.remoteDeviceId);
      return null;
    }

    if (payloadOf(envelope, StartAccept.new) case final accept?) {
      _routes?.ferret.onAccept(session, accept);
      return null;
    }

    if (payloadOf(envelope, StartDeny.new) case final deny?) {
      _routes?.ferret.onDeny(session, deny);
    }

    return null;
  }

  /// A computer asks for this device's screen, or for its camera; or the
  /// device this computer offered its display to said yes.
  Future<GeneratedMessage> _onRequest(
    Session session,
    StartRequest request,
  ) async {
    if (request.source == Source.SOURCE_DISPLAY) {
      final display = _display;
      if (display == null) {
        return StartDeny(reason: .DENY_REASON_UNSUPPORTED);
      }

      return display.onRequest(session, request);
    }

    if (request.source == Source.SOURCE_CAMERA) {
      final camera = _camera;
      if (camera == null) {
        return StartDeny(reason: .DENY_REASON_UNSUPPORTED);
      }

      return camera.onRequest(session, request);
    }

    final source = _source;
    if (source == null) {
      return StartDeny(reason: .DENY_REASON_UNSUPPORTED);
    }

    return source.onRequest(session, request);
  }

  /// A computer offers to extend its desktop onto this one: the owner is
  /// asked here, and a yes shows its display.
  Future<GeneratedMessage> _onDisplayOffer(
    Session session,
    DisplayOffer offer,
  ) async {
    final routes = _routes;
    final viewer = _viewer;
    final deviceId = session.remoteDeviceId;
    if (!canBeDisplay || routes == null || viewer == null) {
      return StartDeny(reason: .DENY_REASON_UNSUPPORTED);
    }

    if (offer.version > MirrorProtocol.version) {
      return StartDeny(reason: .DENY_REASON_VERSION);
    }

    if (routes.displayRequestFrom(deviceId) case final asked?) {
      final left = asked.deadline.difference(_clock());
      return StartPending(timeoutSeconds: left.inSeconds.clamp(0, 3600));
    }

    final showing = viewer.current;
    final busy =
        routes.requests.any((request) => request.display) ||
        (showing != null && showing.isLive && showing.isDisplay);
    if (busy) {
      return StartDeny(reason: .DENY_REASON_BUSY);
    }

    unawaited(_askDisplay(routes, viewer, deviceId));
    return StartPending(timeoutSeconds: routes.askTimeout.inSeconds);
  }

  Future<void> _askDisplay(
    MirrorRoutes routes,
    MirrorViewer viewer,
    String deviceId,
  ) async {
    final askedAt = _clock();
    final allowed = await routes.askDisplay(
      deviceId,
      host.displayNameOf(deviceId),
    );
    if (allowed) {
      await viewer.showDisplay(deviceId);
      return;
    }

    final timedOut = !_clock().isBefore(askedAt.add(routes.askTimeout));
    final session = host.sessionFor(deviceId);
    if (session == null) {
      return;
    }

    try {
      await session.send(
        featureId,
        DisplayDecline(
          reason: switch (timedOut) {
            true => .DENY_REASON_TIMEOUT,
            false => .DENY_REASON_DENIED,
          },
        ),
      );
    } on Object catch (error) {
      printWarning('Answering $deviceId\'s display failed', error);
    }
  }

  /// This computer's screen, the one Ferret shows on, for the computer
  /// that makes a display to fill it.
  Future<DisplayPanel> _ownScreen() async {
    final ScreenPanel? screen;
    try {
      screen = await _displayCapture?.screen();
    } on Object catch (error) {
      printWarning('Could not measure this screen', error);
      return DisplayPanel();
    }

    if (screen == null) {
      return DisplayPanel();
    }

    return DisplayPanel(
      width: screen.width,
      height: screen.height,
      scale: screen.scale,
      refreshHz: screen.refreshHz,
    );
  }

  /// The paired Android devices, which a cable may reach too.
  Map<String, String> _pairedPhones() => {
    for (final device in host.trustStore.devices)
      if (device.platform == .PLATFORM_ANDROID) device.id: device.name,
  };

  static ConsentTexts _plainTexts(
    String deviceName, {
    bool withSound = false,
  }) => ConsentTexts(
    askTitle: '$deviceName wants to see this screen',
    askBody: 'Tap to answer',
    askChannelName: 'Screen sharing requests',
    sharingTitle: switch (withSound) {
      true => 'Sharing screen and sound with $deviceName',
      false => 'Sharing screen with $deviceName',
    },
    sharingBody: switch (withSound) {
      true => 'Everything on this screen is visible there, with sound',
      false => 'Everything on this screen is visible there',
    },
    stopLabel: 'Stop',
    sharingChannelName: 'Screen sharing',
  );

  static CameraTexts _plainCameraTexts(
    String deviceName, {
    bool withSound = false,
  }) => CameraTexts(
    title: 'Camera on for $deviceName',
    body: switch (withSound) {
      true => 'It sees and hears through this phone',
      false => 'It sees through this phone\'s camera',
    },
    stopLabel: 'Stop',
    channelName: 'Camera for a computer',
  );

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
