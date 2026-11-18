import 'dart:async';

import 'package:ferret_power/src/messages.g.dart';
import 'package:ferret_power/src/power_clip.dart';
import 'package:ferret_power/src/power_grant.dart';
import 'package:ferret_power/src/power_platform.dart';
import 'package:ferret_power/src/power_status.dart';
import 'package:ferret_power/src/power_tier.dart';

/// The power-ups through the Android plugin.
class PigeonPowerPlatform implements PowerPlatform, PowerFlutterApi {
  PigeonPowerPlatform({PowerHostApi? api}) : _api = api ?? PowerHostApi() {
    PowerFlutterApi.setUp(this);
  }

  final PowerHostApi _api;
  final StreamController<PowerStatus> _statusChanges = .broadcast();
  final StreamController<PowerClip> _clipboardChanges = .broadcast();
  final StreamController<void> _watchStops = .broadcast();

  @override
  Stream<PowerStatus> get statusChanges => _statusChanges.stream;

  @override
  Stream<PowerClip> get clipboardChanges => _clipboardChanges.stream;

  @override
  Stream<void> get watchStops => _watchStops.stream;

  @override
  Future<PowerStatus> status() async => statusOf(await _api.getState());

  @override
  Future<bool> requestShizukuPermission() => _api.requestShizukuPermission();

  @override
  Future<bool> requestRoot() => _api.requestRoot();

  @override
  Future<bool> openShizuku() => _api.openShizuku();

  @override
  Future<bool> openNotificationAccessSettings() =>
      _api.openNotificationAccessSettings();

  @override
  Future<bool> openAppSettings() => _api.openAppSettings();

  @override
  Future<PowerClip?> readClipboard(PowerTier tier) async {
    final backend = _backendOf(tier);
    if (backend == null) {
      return null;
    }

    final clip = await _api.readClipboard(backend);
    if (clip == null || clip.text.isEmpty) {
      return null;
    }

    return PowerClip(clip.text, sensitive: clip.sensitive);
  }

  @override
  Future<void> startClipboardWatch(PowerTier tier) async {
    final backend = _backendOf(tier);
    if (backend == null) {
      return;
    }

    await _api.startClipboardWatch(backend);
  }

  @override
  Future<void> stopClipboardWatch() => _api.stopClipboardWatch();

  @override
  Future<bool> grant(PowerTier tier, PowerGrant grant) async {
    final backend = _backendOf(tier);
    if (backend == null) {
      return false;
    }

    return _api.grant(backend, switch (grant) {
      .notificationAccess => PlatformPowerGrant.notificationAccess,
      .batteryUnrestricted => PlatformPowerGrant.batteryUnrestricted,
    });
  }

  @override
  void onStateChanged(PlatformPowerState state) =>
      _statusChanges.add(statusOf(state));

  @override
  void onClipboardChanged(PlatformPowerClip clip) {
    if (clip.text.isEmpty) {
      return;
    }

    _clipboardChanges.add(PowerClip(clip.text, sensitive: clip.sensitive));
  }

  @override
  void onClipboardWatchStopped() => _watchStops.add(null);

  /// What the native flags add up to: the next thing to fix for Shizuku, and
  /// how far root got.
  static PowerStatus statusOf(PlatformPowerState state) => PowerStatus(
    supported: true,
    shizuku: _shizukuOf(state),
    root: _rootOf(state),
    rootManager: switch (state.rootManager) {
      .none => .none,
      .magisk => .magisk,
      .kernelSu => .kernelSu,
      .aPatch => .aPatch,
      .unknown => .unknown,
    },
    notificationAccess: state.notificationAccess,
    messagesAndCalls: state.messagesAndCalls,
    batteryUnrestricted: state.batteryUnrestricted,
  );

  static ShizukuStatus _shizukuOf(PlatformPowerState state) {
    if (state.shizukuRunning && state.shizukuGranted) {
      return .ready;
    }

    if (state.shizukuRunning) {
      return .notAuthorized;
    }

    if (state.shizukuInstalled) {
      return .notRunning;
    }

    return .notInstalled;
  }

  static RootStatus _rootOf(PlatformPowerState state) {
    if (state.rootGranted) {
      return .granted;
    }

    if (state.rootFound) {
      return .found;
    }

    return .notFound;
  }

  static PlatformPowerBackend? _backendOf(PowerTier tier) => switch (tier) {
    .standard => null,
    .shizuku => .shizuku,
    .root => .root,
  };
}
