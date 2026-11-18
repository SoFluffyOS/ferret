import 'dart:async';
import 'dart:io';

import 'package:ferret_find/src/alert_stop.dart';
import 'package:ferret_find/src/audio_state.dart';
import 'package:ferret_find/src/find_platform.dart';
import 'package:ferret_find/src/messages.g.dart';
import 'package:ferret_find/src/ring_abilities.dart';
import 'package:ferret_find/src/ring_alert.dart';

/// Ringing through the native plugin (Android, iOS, macOS).
class PigeonFind implements FindPlatform, FindFlutterApi {
  PigeonFind({FindHostApi? api, bool? isIos})
    : _api = api ?? FindHostApi(),
      _isIos = isIos ?? Platform.isIOS {
    FindFlutterApi.setUp(this);
  }

  final FindHostApi _api;
  final bool _isIos;
  final StreamController<AlertStop> _stops = .broadcast();

  @override
  Stream<AlertStop> get stops => _stops.stream;

  @override
  Future<RingAbilities> abilities() async {
    final abilities = await _api.abilities();
    return RingAbilities(
      controlsVolume: abilities.controlsVolume,
      needsDndAccess: abilities.needsDndAccess,
      dndAccessGranted: abilities.dndAccessGranted,
      fullScreenAllowed: abilities.fullScreenAllowed,
      hasTorch: abilities.hasTorch,
      ringsInBackground: abilities.ringsInBackground,
      showsOwnAlert: abilities.showsOwnAlert,
      ignoresSilentSwitch: _isIos,
    );
  }

  @override
  Future<AudioState?> readAudio() async {
    final audio = await _api.readAudio();
    if (audio == null) {
      return null;
    }

    return AudioState(
      volume: audio.volume,
      maxVolume: audio.maxVolume,
      muted: audio.muted,
      interruptionFilter: audio.interruptionFilter,
      quiet: audio.quiet,
    );
  }

  @override
  Future<void> applyAudio(AudioState state) => _api.applyAudio(
    PlatformAudio(
      volume: state.volume,
      maxVolume: state.maxVolume,
      muted: state.muted,
      interruptionFilter: state.interruptionFilter,
      quiet: state.quiet,
    ),
  );

  @override
  Future<void> startAlert(RingAlert alert) => _api.startAlert(
    PlatformAlert(
      title: alert.title,
      body: alert.body,
      foundItLabel: alert.foundItLabel,
      silent: alert.silent,
      vibrate: alert.vibrate,
      flashTorch: alert.flashTorch,
      maxSeconds: alert.maxDuration.inSeconds,
    ),
  );

  @override
  Future<void> stopAlert() => _api.stopAlert();

  @override
  Future<void> openDndAccessSettings() => _api.openDndAccessSettings();

  @override
  Future<void> openFullScreenSettings() => _api.openFullScreenSettings();

  @override
  void onAlertStopped(String reason) {
    if (AlertStop.fromNative(reason) case final stop?) {
      _stops.add(stop);
    }
  }
}
