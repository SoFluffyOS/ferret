import 'dart:async';
import 'dart:io';

import 'package:ferret_remote_input/src/keys/keys.dart';
import 'package:ferret_remote_input/src/messages.g.dart';

/// What this computer lets Ferret do to take its own keyboard and mouse.
class CaptureAccess {
  const CaptureAccess({
    required this.inputMonitoring,
    required this.accessibility,
  });

  /// Seeing keys typed in other apps (Input Monitoring on macOS).
  final bool inputMonitoring;

  /// Holding events back from other apps (Accessibility on macOS).
  final bool accessibility;

  bool get isGranted => inputMonitoring && accessibility;

  @override
  bool operator ==(Object other) =>
      other is CaptureAccess &&
      other.inputMonitoring == inputMonitoring &&
      other.accessibility == accessibility;

  @override
  int get hashCode => Object.hash(inputMonitoring, accessibility);

  @override
  String toString() => 'CaptureAccess($inputMonitoring, $accessibility)';
}

/// Takes this computer's own keyboard and mouse away from it, to use them
/// on another one, and listens for the keys that switch: ⌃⌥→ and ⌃⌥⎋.
/// macOS only for now.
abstract interface class InputCapture {
  factory InputCapture.current() {
    if (Platform.isMacOS) {
      return MacInputCapture();
    }

    return UnsupportedInputCapture();
  }

  static bool get isSupportedPlatform => Platform.isMacOS;

  Future<CaptureAccess> access();

  /// Shows the system prompts; each shows only once.
  Future<CaptureAccess> requestAccess();

  /// Opens the system page where the missing access is turned on.
  Future<void> openAccessSettings();

  /// A password field holds secure input, which hides keys from Ferret.
  Future<bool> secureInputOn();

  /// Listens for the switch keys anywhere, or stops. False when the system
  /// refused them.
  Future<bool> setSwitchKeys({required bool enabled});

  /// Starts taking every key and mouse event. Returns the modifiers held
  /// right now, or null when it couldn't start.
  Future<Set<KeyModifier>?> start();

  /// Gives the keyboard and mouse back.
  Future<void> stop();

  /// What was taken, in order.
  Stream<List<NativeCapturedEvent>> get events;

  Stream<NativeSwitchKey> get switchKeys;

  /// Capture stopped on its own, with the keyboard and mouse back already.
  Stream<NativeCaptureEnd> get ends;
}

/// The macOS event tap, through the plugin.
class MacInputCapture implements InputCapture, InputCaptureFlutterApi {
  factory MacInputCapture({InputCaptureHostApi? api}) =>
      _instance ??= MacInputCapture._(api ?? InputCaptureHostApi());

  MacInputCapture._(this._api) {
    InputCaptureFlutterApi.setUp(this);
  }

  /// One per app: the plugin talks to one listener.
  static MacInputCapture? _instance;

  final InputCaptureHostApi _api;
  final StreamController<List<NativeCapturedEvent>> _events = .broadcast(
    sync: true,
  );
  final StreamController<NativeSwitchKey> _switchKeys = .broadcast();
  final StreamController<NativeCaptureEnd> _ends = .broadcast();

  @override
  Future<CaptureAccess> access() async => _accessOf(await _api.captureAccess());

  @override
  Future<CaptureAccess> requestAccess() async {
    await _api.requestCaptureAccess();
    return access();
  }

  @override
  Future<void> openAccessSettings() => _api.openCaptureSettings();

  @override
  Future<bool> secureInputOn() => _api.secureInputOn();

  @override
  Future<bool> setSwitchKeys({required bool enabled}) =>
      _api.setSwitchKeys(enabled);

  @override
  Future<Set<KeyModifier>?> start() async {
    final bits = await _api.startCapture();
    if (bits < 0) {
      return null;
    }

    return {
      for (final modifier in KeyModifier.values)
        if (bits & modifier.bit != 0) modifier,
    };
  }

  @override
  Future<void> stop() => _api.stopCapture();

  @override
  Stream<List<NativeCapturedEvent>> get events => _events.stream;

  @override
  Stream<NativeSwitchKey> get switchKeys => _switchKeys.stream;

  @override
  Stream<NativeCaptureEnd> get ends => _ends.stream;

  @override
  void onCaptured(List<NativeCapturedEvent> events) => _events.add(events);

  @override
  void onSwitchKey(NativeSwitchKey key) => _switchKeys.add(key);

  @override
  void onCaptureEnded(NativeCaptureEnd reason) => _ends.add(reason);

  CaptureAccess _accessOf(NativeCaptureAccess access) => CaptureAccess(
    inputMonitoring: access.inputMonitoring,
    accessibility: access.accessibility,
  );
}

/// Where taking the keyboard and mouse isn't built yet.
class UnsupportedInputCapture implements InputCapture {
  static const _none = CaptureAccess(
    inputMonitoring: false,
    accessibility: false,
  );

  @override
  Future<CaptureAccess> access() async => _none;

  @override
  Future<CaptureAccess> requestAccess() async => _none;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<bool> secureInputOn() async => false;

  @override
  Future<bool> setSwitchKeys({required bool enabled}) async => !enabled;

  @override
  Future<Set<KeyModifier>?> start() async => null;

  @override
  Future<void> stop() async {}

  @override
  Stream<List<NativeCapturedEvent>> get events => const Stream.empty();

  @override
  Stream<NativeSwitchKey> get switchKeys => const Stream.empty();

  @override
  Stream<NativeCaptureEnd> get ends => const Stream.empty();
}
