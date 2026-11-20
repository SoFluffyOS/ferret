import 'dart:async';

import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:ferret_phone_control/ferret_phone_control.dart';
import 'package:flutter/foundation.dart';
import 'package:mirroring/feature/mirroring_feature.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/services/services.dart';

/// What the phone's card and settings show while computers ask for or see
/// its screen, and what they can do.
class ShareViewModel extends ChangeNotifier {
  ShareViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => notifyListeners());
  }

  final MirroringFeature feature;
  late final StreamSubscription<void> _subscription;
  bool _soundDenied = false;

  MirrorSource? get _source => feature.source;

  bool get isAvailable => _source != null;

  /// Whether this phone can capture its screen at all.
  bool get canCapture => _source?.support.canCapture ?? false;

  /// Whether this phone can send what it plays at all: Android 10 and
  /// newer.
  bool get canSendSound =>
      (_source?.soundSupport ?? AudioCaptureSupport.unsupported) !=
      AudioCaptureSupport.unsupported;

  /// Sound goes along with the screen.
  bool get sendSound => _source?.sendsSound ?? false;

  /// The owner just turned sound on and Android said no.
  bool get soundDenied => _soundDenied;

  /// Turning it on is when Android asks for its permission.
  Future<void> setSendSound(bool value) async {
    final applied = await _source?.setSendSound(value) ?? false;
    _soundDenied = value && !applied;
    notifyListeners();
  }

  ShareRequest? get pending => _source?.pending;

  ActiveShare? get active => _source?.active;

  /// The audit line to show: the screen's or the camera's, whichever
  /// ended last.
  MirrorRecord? get lastRecord {
    final screen = _source?.lastRecord;
    final camera = _camera?.lastRecord;
    if (screen == null || camera == null) {
      return screen ?? camera;
    }

    if (camera.endedAt.isAfter(screen.endedAt)) {
      return camera;
    }

    return screen;
  }

  bool get enabled => feature.settings.enabled;

  List<MirrorRecord> get history => feature.settings.history;

  bool get hasCard =>
      pending != null ||
      active != null ||
      lastRecord != null ||
      controlPending != null ||
      cameraPending != null ||
      cameraActive != null;

  Future<void> stop() async => _source?.stop();

  Future<void> setEnabled(bool value) async => _source?.setEnabled(value);

  /// Whether the computer [deviceId] may ask to see this screen.
  bool mayAsk(String deviceId) => !feature.settings.isBlocked(deviceId);

  Future<void> setMayAsk(String deviceId, bool value) async =>
      _source?.setBlocked(deviceId, !value);

  void dismissRecord() {
    _source?.dismissRecord();
    _camera?.dismissRecord();
  }

  CameraSource? get _camera => feature.camera;

  /// Whether this phone has a camera it can send to a computer.
  bool get canSendCamera => _camera?.support.canCapture ?? false;

  /// Computers may ask for the camera.
  bool get cameraEnabled => _camera?.enabled ?? false;

  Future<void> setCameraEnabled(bool value) async => _camera?.setEnabled(value);

  /// A computer asking to use this phone's camera.
  ShareRequest? get cameraPending => _camera?.pending;

  /// The computer this phone's camera is on for right now.
  ActiveCamera? get cameraActive => _camera?.active;

  /// How many computers turn the camera on without asking.
  int get cameraAlwaysCount => _camera?.alwaysAllowed.length ?? 0;

  Future<void> answerCamera(ControlChoice choice) async =>
      _camera?.answer(choice);

  Future<void> stopCamera() async => _camera?.stop();

  Future<void> forgetCameraAlways() async => _camera?.forgetAlways();

  /// Whether the computer [deviceId] may ask for this phone's camera.
  bool mayAskCamera(String deviceId) =>
      !feature.settings.isCameraBlocked(deviceId);

  Future<void> setMayAskCamera(String deviceId, bool value) async =>
      _camera?.setBlocked(deviceId, !value);

  SourceControl? get _control => _source?.control;

  /// Whether a computer could ever control this phone.
  bool get canBeControlled => _control?.isSupported ?? false;

  /// What would carry a computer's taps right now.
  ControlPath get controlPath => _control?.path ?? .none;

  /// A computer that sees this screen, asking to control it.
  ControlRequest? get controlPending => _control?.pending;

  /// The computer controlling this phone right now.
  ControlRequest? get controller => _control?.controller;

  /// How many computers control this phone without asking.
  int get controlAlwaysCount => _control?.alwaysAllowed.length ?? 0;

  /// This phone's own name, for the question.
  String get phoneName => feature.host.localDevice.name;

  Future<void> answerControl(ControlChoice choice) async =>
      _control?.answer(choice);

  Future<void> stopControl() async => _control?.stop();

  Future<bool> openControlSettings() async =>
      await _control?.openServiceSettings() ?? false;

  Future<void> forgetControlAlways() async => _control?.forgetAlways();

  Future<void> clearHistory() async => _source?.clearHistory();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
