import 'dart:async';
import 'dart:io' as io;

import 'package:engine/engine.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/services.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/mirroring.dart';
import 'package:protocol/protocol.dart';

/// See an Android phone's screen on a computer. The computer asks; the
/// phone's owner answers Android's own prompt every time, sees an ongoing
/// "Sharing screen" notice with Stop, and both sides keep an audit line.
class MirroringFeature extends Feature {
  MirroringFeature({
    ScreenCapture Function()? capture,
    PhoneControl Function()? phoneControl,
    MirrorDecoder Function()? decoder,
    List<MirrorCodec>? codecs,
    AudioSink Function()? audioSink,
    List<MirrorAudioCodec>? audioCodecs,
    List<MirrorRoute> routes = const [],
    List<MirrorReceiver> receivers = const [],
    bool? canShare,
    bool? canView,
    ConsentTexts Function(String deviceName, {bool withSound})? texts,
    DateTime Function()? clock,
    this.consentTimeout = const Duration(seconds: 60),
    this.requestTimeout = const Duration(seconds: 10),
    this.firstPictureTimeout = const Duration(seconds: 10),
  }) : _createCapture = capture ?? ScreenCapture.current,
       _createPhoneControl = phoneControl ?? PhoneControl.new,
       _createDecoder = decoder ?? MirrorDecoder.current,
       _codecs = codecs,
       _createAudioSink = audioSink,
       _audioCodecs = audioCodecs,
       _extraRoutes = routes,
       _receivers = receivers,
       canShare = canShare ?? ScreenCapture.isSupportedPlatform,
       canView =
           canView ??
           (io.Platform.isMacOS ||
               io.Platform.isWindows ||
               io.Platform.isLinux),
       _clock = clock ?? DateTime.now {
    if (texts != null) {
      this.texts = texts;
    }
  }

  static const featureId = 'mirroring';

  /// Flag in [FeatureSupport]: this device can show its screen.
  static const shareFlag = MirrorProtocol.shareFlag;

  /// Flag in [FeatureSupport]: this device can show another's screen.
  static const viewFlag = MirrorProtocol.viewFlag;

  /// This device's screen can be captured: Android phones and tablets.
  final bool canShare;

  /// This device shows other screens: computers.
  final bool canView;

  final Duration consentTimeout;
  final Duration requestTimeout;
  final Duration firstPictureTimeout;

  /// The words on the phone's own notices. The app sets them in the
  /// owner's language before any request can arrive.
  ConsentTexts Function(String deviceName, {bool withSound}) texts =
      _plainTexts;

  final ScreenCapture Function() _createCapture;
  final PhoneControl Function() _createPhoneControl;
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
  MirrorViewer? _viewer;
  MirrorRoutes? _routes;

  @override
  String get id => featureId;

  @override
  List<String> get flags => [if (canShare) shareFlag, if (canView) viewFlag];

  MirroringSettings get settings => MirroringSettings(host.settings);

  /// The phone's side, or null on computers.
  MirrorSource? get source => _source;

  /// The computer's side, or null on phones.
  MirrorViewer? get viewer => _viewer;

  /// Every way a screen can arrive here, or null on phones: Ferret's own
  /// route, and the routes and receivers the app plugged in.
  MirrorRoutes? get routes => _routes;

  /// Fires when anything the cards, health or settings show may have
  /// changed. The picture's numbers come from the viewer instead.
  Stream<void> get changes => _changes.stream;

  /// Whether [session]'s device can show its screen here.
  bool canViewDevice(Session session) =>
      canView && (_routes?.ferret.canShow(session) ?? false);

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
        clock: _clock,
        consentTimeout: consentTimeout,
      );
      _source = source;
      _subscriptions.add(source.changes.listen((_) => _emit()));
      await source.start();
    }

    if (canView) {
      final routes = MirrorRoutes(
        ferret: FerretRoute(
          host: host,
          featureId: featureId,
          clock: _clock,
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
    await _viewer?.dispose();
    await _routes?.dispose();
  }

  @override
  void onSessionClosed(Session session) {
    final deviceId = session.remoteDeviceId;
    unawaited(_source?.onSessionClosed(deviceId));
    _routes?.ferret.onSessionClosed(deviceId);
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
      final source = _source;
      if (source == null) {
        return StartDeny(reason: .DENY_REASON_UNSUPPORTED);
      }

      return source.onRequest(session, request);
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
      _routes?.ferret.onStats(session, stats);
      return null;
    }

    if (payloadOf(envelope, KeyframeRequest.new) != null) {
      await _source?.onKeyframeRequest(session);
      return null;
    }

    if (payloadOf(envelope, SourceState.new) case final state?) {
      _routes?.ferret.onSourceState(session, state);
      return null;
    }

    if (payloadOf(envelope, Stop.new) case final stop?) {
      await _source?.onStop(session);
      _routes?.ferret.onStop(session, stop);
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

  void _emit() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
