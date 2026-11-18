import 'dart:async';

import 'package:ferret_power/src/power_clip.dart';
import 'package:ferret_power/src/power_grant.dart';
import 'package:ferret_power/src/power_platform.dart';
import 'package:ferret_power/src/power_status.dart';
import 'package:ferret_power/src/power_tier.dart';
import 'package:flutter/foundation.dart';

/// What Ferret can do beyond a normal Android app, and the one door to it.
///
/// A tier counts only when the user turned it on ([setShizukuEnabled],
/// [enableRoot]) *and* the phone agrees right now. Until then [activeTier] is
/// [PowerTier.standard] and every capability here is a no-op: nothing is
/// read, watched or granted, and no shell is started.
class PowerCapabilities {
  /// The one instance the app shares, so every feature sees the same tier.
  factory PowerCapabilities() =>
      _shared ??= PowerCapabilities.withPlatform(PowerPlatform.current());

  PowerCapabilities.withPlatform(this._platform) {
    _clips = .broadcast(onListen: _syncWatch, onCancel: _syncWatch);
    _subscriptions = [
      _platform.statusChanges.listen(_apply),
      _platform.clipboardChanges.listen(_onClip),
      _platform.watchStops.listen((_) => unawaited(_onWatchStopped())),
    ];
  }

  /// A watch that keeps ending is left alone after this many tries, until
  /// the tier changes or someone calls [refresh].
  static const maxWatchRestarts = 3;

  static PowerCapabilities? _shared;

  final PowerPlatform _platform;
  final StreamController<PowerStatus> _statusChanges = .broadcast();
  final StreamController<PowerTier> _tierChanges = .broadcast();
  late final StreamController<PowerClip> _clips;
  late final List<StreamSubscription<Object?>> _subscriptions;

  PowerStatus _status = .unsupported;
  PowerTier _tier = .standard;
  bool _shizukuEnabled = false;
  bool _rootEnabled = false;
  bool _rootChecked = false;
  PowerTier? _watchedTier;
  int _watchRestarts = 0;
  Future<void> _watchQueue = Future.value();

  /// What the phone offers, as of the last [refresh] or native event.
  PowerStatus get status => _status;

  Stream<PowerStatus> get statusChanges => _statusChanges.stream;

  /// The highest tier that is both turned on and working right now.
  PowerTier get activeTier => _tier;

  Stream<PowerTier> get tierChanges => _tierChanges.stream;

  bool get shizukuEnabled => _shizukuEnabled;

  bool get rootEnabled => _rootEnabled;

  /// Whether a background clipboard watch is running right now.
  bool get isWatchingClipboard => _watchedTier != null;

  /// Text copied anywhere on the phone, also while the app is in the
  /// background. The watch runs only while someone listens *and* a tier is
  /// active; it starts and stops by itself as the tier comes and goes.
  Stream<PowerClip> get clipboardChanges => _clips.stream;

  /// Applies what the user chose earlier, at startup. With root turned on,
  /// checks once that `su` still says yes.
  Future<void> configure({required bool shizuku, required bool root}) async {
    _shizukuEnabled = shizuku;
    _rootEnabled = root;
    _rootChecked = false;

    await refresh();
  }

  /// Reads the phone's state again, such as when the user comes back from
  /// Shizuku or the system settings.
  Future<void> refresh() async {
    _watchRestarts = 0;
    await _reload();
  }

  /// Lets Ferret use Shizuku once it is running and authorized, or stops
  /// using it.
  void setShizukuEnabled(bool enabled) {
    _shizukuEnabled = enabled;
    _apply(_status);
  }

  /// Shows Shizuku's permission dialog and turns the tier on when the user
  /// agrees.
  Future<bool> authorizeShizuku() async {
    final granted = await _guarded(_platform.requestShizukuPermission);
    if (granted) {
      _shizukuEnabled = true;
    }

    await refresh();
    return granted;
  }

  /// Asks `su` for root, which makes the root manager ask the user, and
  /// turns the tier on when it says yes.
  Future<bool> enableRoot() async {
    final granted = await _guarded(_platform.requestRoot);
    _rootEnabled = granted;
    _rootChecked = true;

    await refresh();
    return granted;
  }

  void disableRoot() {
    _rootEnabled = false;
    _apply(_status);
  }

  Future<bool> openShizuku() => _guarded(_platform.openShizuku);

  Future<bool> openNotificationAccessSettings() =>
      _guarded(_platform.openNotificationAccessSettings);

  Future<bool> openAppSettings() => _guarded(_platform.openAppSettings);

  /// The clipboard text right now, read through the active tier. Null on the
  /// standard tier, when the clipboard is empty, or when it holds something
  /// other than text.
  Future<PowerClip?> readClipboard() async {
    final tier = _tier;
    if (tier == .standard) {
      return null;
    }

    try {
      return await _platform.readClipboard(tier);
    } on Object {
      return null;
    }
  }

  /// Turns [grant] on for Ferret through the active tier. False on the
  /// standard tier or when the command failed.
  Future<bool> grant(PowerGrant grant) async {
    final tier = _tier;
    if (tier == .standard) {
      return false;
    }

    final granted = await _guarded(() => _platform.grant(tier, grant));
    await _reload();
    return granted;
  }

  @visibleForTesting
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    await _statusChanges.close();
    await _tierChanges.close();
    await _clips.close();
  }

  Future<void> _reload() async {
    final PowerStatus status;
    try {
      status = await _checked(await _platform.status());
    } on Object {
      return;
    }

    _apply(status);
  }

  /// With root turned on by the user, asks `su` once per run whether it
  /// still agrees. Never asks when root is off.
  Future<PowerStatus> _checked(PowerStatus status) async {
    if (!_rootEnabled || _rootChecked || status.root != .found) {
      return status;
    }

    _rootChecked = true;
    await _guarded(_platform.requestRoot);
    return _platform.status();
  }

  void _apply(PowerStatus status) {
    final tier = _tierOf(status);
    final statusChanged = status != _status;
    final tierChanged = tier != _tier;
    _status = status;
    _tier = tier;

    if (statusChanged) {
      _statusChanges.add(status);
    }

    if (tierChanged) {
      _watchRestarts = 0;
      _tierChanges.add(tier);
    }

    _syncWatch();
  }

  PowerTier _tierOf(PowerStatus status) {
    if (_rootEnabled && status.root == .granted) {
      return .root;
    }

    if (_shizukuEnabled && status.shizuku == .ready) {
      return .shizuku;
    }

    return .standard;
  }

  void _onClip(PowerClip clip) {
    if (_watchedTier == null || _tier == .standard) {
      return;
    }

    _watchRestarts = 0;
    _clips.add(clip);
  }

  Future<void> _onWatchStopped() async {
    if (_watchedTier == null) {
      return;
    }

    _watchedTier = null;
    _watchRestarts++;
    await _reload();
  }

  void _syncWatch() {
    _watchQueue = _watchQueue.then((_) => _applyWatch());
  }

  Future<void> _applyWatch() async {
    final wanted = _wantedWatch();
    if (wanted == _watchedTier) {
      return;
    }

    if (_watchedTier != null) {
      _watchedTier = null;
      await _guarded(() async {
        await _platform.stopClipboardWatch();
        return true;
      });
    }

    if (wanted == null || _watchRestarts >= maxWatchRestarts) {
      return;
    }

    final started = await _guarded(() async {
      await _platform.startClipboardWatch(wanted);
      return true;
    });
    if (started) {
      _watchedTier = wanted;
      return;
    }

    _watchRestarts++;
  }

  PowerTier? _wantedWatch() {
    if (!_clips.hasListener || _tier == .standard) {
      return null;
    }

    return _tier;
  }

  /// A platform call that failed counts as "no": the tier ladder shows why.
  Future<bool> _guarded(Future<bool> Function() call) async {
    try {
      return await call();
    } on Object {
      return false;
    }
  }
}
