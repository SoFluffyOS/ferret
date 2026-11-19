import 'dart:async';

import 'package:ferret_power/src/power_clip.dart';
import 'package:ferret_power/src/power_grant.dart';
import 'package:ferret_power/src/power_input.dart';
import 'package:ferret_power/src/power_platform.dart';
import 'package:ferret_power/src/power_status.dart';
import 'package:ferret_power/src/power_tier.dart';

/// A phone in memory: tests set what it offers, and it records every call
/// that would have run something for real.
class FakePowerPlatform implements PowerPlatform {
  FakePowerPlatform({PowerStatus status = const PowerStatus(supported: true)})
    : _status = status;

  final StreamController<PowerStatus> _statusChanges = .broadcast();
  final StreamController<PowerClip> _clipboardChanges = .broadcast();
  final StreamController<void> _watchStops = .broadcast();
  PowerStatus _status;

  /// What the clipboard holds.
  PowerClip? clip;

  /// How the user answers Shizuku's dialog and the root manager's prompt.
  bool shizukuAnswer = true;
  bool rootAnswer = true;

  bool failWatch = false;
  bool failGrants = false;
  bool failInput = false;

  /// Everything injected, in order, and how often input was released.
  final List<PowerInput> injected = [];
  int inputReleases = 0;

  /// The tier a watch runs on, or null when none does.
  PowerTier? watchedTier;

  /// Calls that reached a shell: `read:shizuku`, `watch:root`,
  /// `grant:shizuku:notificationAccess`, `stop`.
  final List<String> shellCalls = [];
  int rootRequests = 0;
  int shizukuRequests = 0;
  final List<String> opened = [];

  PowerStatus get current => _status;

  /// The phone changed, such as Shizuku starting, and says so.
  void emit(PowerStatus status) {
    _status = status;
    _statusChanges.add(status);
  }

  /// The phone changed without an event, such as a setting flipped in the
  /// system settings.
  void setQuietly(PowerStatus status) => _status = status;

  /// Someone copied [text] in another app while a watch runs.
  void copy(String text, {bool sensitive = false}) {
    clip = PowerClip(text, sensitive: sensitive);
    _clipboardChanges.add(PowerClip(text, sensitive: sensitive));
  }

  /// The watch ended on its own.
  void stopWatch() {
    watchedTier = null;
    _watchStops.add(null);
  }

  @override
  Stream<PowerStatus> get statusChanges => _statusChanges.stream;

  @override
  Stream<PowerClip> get clipboardChanges => _clipboardChanges.stream;

  @override
  Stream<void> get watchStops => _watchStops.stream;

  @override
  Future<PowerStatus> status() async => _status;

  @override
  Future<bool> requestShizukuPermission() async {
    shizukuRequests++;
    if (_status.shizuku == .notInstalled || _status.shizuku == .notRunning) {
      return false;
    }

    if (shizukuAnswer) {
      _status = _with(shizuku: .ready);
    }

    return shizukuAnswer;
  }

  @override
  Future<bool> requestRoot() async {
    rootRequests++;
    if (_status.root == .notFound) {
      return false;
    }

    _status = _with(
      root: switch (rootAnswer) {
        true => .granted,
        false => .found,
      },
    );
    return rootAnswer;
  }

  @override
  Future<bool> openShizuku() async {
    opened.add('shizuku');
    return _status.shizuku != .notInstalled;
  }

  @override
  Future<bool> openNotificationAccessSettings() async {
    opened.add('notificationAccess');
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    opened.add('appSettings');
    return true;
  }

  @override
  Future<PowerClip?> readClipboard(PowerTier tier) async {
    shellCalls.add('read:${tier.name}');
    return clip;
  }

  @override
  Future<void> startClipboardWatch(PowerTier tier) async {
    shellCalls.add('watch:${tier.name}');
    if (failWatch) {
      throw StateError('watch failed');
    }

    watchedTier = tier;
  }

  @override
  Future<void> stopClipboardWatch() async {
    shellCalls.add('stop');
    watchedTier = null;
  }

  @override
  Future<bool> grant(PowerTier tier, PowerGrant grant) async {
    shellCalls.add('grant:${tier.name}:${grant.name}');
    if (failGrants) {
      return false;
    }

    _status = switch (grant) {
      .notificationAccess => _with(notificationAccess: true),
      .batteryUnrestricted => _with(batteryUnrestricted: true),
    };
    return true;
  }

  @override
  Future<bool> inject(PowerTier tier, PowerInput input) async {
    if (failInput) {
      return false;
    }

    injected.add(input);
    return true;
  }

  @override
  Future<void> releaseInput() async => inputReleases++;

  PowerStatus _with({
    ShizukuStatus? shizuku,
    RootStatus? root,
    bool? notificationAccess,
    bool? batteryUnrestricted,
  }) => PowerStatus(
    supported: _status.supported,
    shizuku: shizuku ?? _status.shizuku,
    root: root ?? _status.root,
    rootManager: _status.rootManager,
    notificationAccess: notificationAccess ?? _status.notificationAccess,
    messagesAndCalls: _status.messagesAndCalls,
    batteryUnrestricted: batteryUnrestricted ?? _status.batteryUnrestricted,
  );
}
