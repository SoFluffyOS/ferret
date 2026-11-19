import 'dart:async';

import 'package:core/core.dart';

/// Which features each paired device may use with this one. Everything is
/// allowed until the person turns a feature off for a device; that device
/// then can't send or receive anything for it, as if this device didn't
/// have the feature at all.
class DeviceAccess {
  DeviceAccess(this._settings);

  /// Setting: device id to the feature ids it may not use.
  static const blockedKey = 'access.blocked_features';

  final SettingsStore _settings;
  final StreamController<String> _changes = .broadcast();

  /// Fires with the id of the device whose access changed.
  Stream<String> get changes => _changes.stream;

  /// The features [deviceId] may not use with this device.
  Set<String> blockedFor(String deviceId) => switch (_stored()[deviceId]) {
    final List<Object?> features => {...features.whereType<String>()},
    _ => const {},
  };

  bool isBlocked(String deviceId, String featureId) =>
      blockedFor(deviceId).contains(featureId);

  Future<void> setAllowed(
    String deviceId,
    String featureId, {
    required bool allowed,
  }) async {
    final blocked = {...blockedFor(deviceId)};
    final changed = switch (allowed) {
      true => blocked.remove(featureId),
      false => blocked.add(featureId),
    };
    if (!changed) {
      return;
    }

    await _save(deviceId, blocked);
  }

  /// Turns every feature in [featureIds] off for [deviceId] at once.
  Future<void> blockAll(String deviceId, Iterable<String> featureIds) async {
    final blocked = {...blockedFor(deviceId), ...featureIds};
    if (blocked.length == blockedFor(deviceId).length) {
      return;
    }

    await _save(deviceId, blocked);
  }

  /// Drops what was chosen for [deviceId], such as once it is forgotten.
  Future<void> forget(String deviceId) async {
    if (!_stored().containsKey(deviceId)) {
      return;
    }

    await _save(deviceId, const {});
  }

  Map<String, Object?> _stored() => switch (_settings.get<Object?>(
    blockedKey,
  )) {
    final Map<String, Object?> stored => stored,
    _ => const {},
  };

  Future<void> _save(String deviceId, Set<String> blocked) async {
    final stored = {..._stored()};
    if (blocked.isEmpty) {
      stored.remove(deviceId);
    }

    if (blocked.isNotEmpty) {
      stored[deviceId] = [...blocked]..sort();
    }

    await _settings.set(blockedKey, stored);
    _changes.add(deviceId);
  }
}
