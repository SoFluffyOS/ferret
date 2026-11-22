import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:shell/services/device_successors.dart';

/// How the user keeps a long device list in order: devices pinned to the
/// top, and when each was last used from here. Lives in settings and never
/// leaves this device.
class DevicePreferences {
  const DevicePreferences(this._settings);

  final SettingsStore _settings;

  static const pinnedKey = 'shell.pinned_devices';
  static const lastUsedKey = 'shell.devices_last_used';

  /// An offline device not seen for this long is offered for removal.
  static const staleAfter = Duration(days: 30);

  Set<String> get pinned => {
    for (final id in _settings.get<List<dynamic>>(pinnedKey) ?? const [])
      if (id case final String deviceId) deviceId,
  };

  bool isPinned(String deviceId) => pinned.contains(deviceId);

  Future<void> setPinned(String deviceId, {required bool pinned}) async {
    final updated = {...this.pinned};
    switch (pinned) {
      case true:
        updated.add(deviceId);
      case false:
        updated.remove(deviceId);
    }

    await _settings.set(pinnedKey, updated.toList());
  }

  DateTime? lastUsed(String deviceId) {
    final stored = _settings.get<Map<String, dynamic>>(lastUsedKey);
    return switch (stored?[deviceId]) {
      final int millis => DateTime.fromMillisecondsSinceEpoch(millis),
      _ => null,
    };
  }

  Future<void> markUsed(String deviceId, {DateTime? at}) async {
    final stored = _settings.get<Map<String, dynamic>>(lastUsedKey) ?? {};
    final millis = (at ?? DateTime.now()).millisecondsSinceEpoch;

    await _settings.set(lastUsedKey, {...stored, deviceId: millis});
  }

  /// Takes a removed device out of the pins and the last uses.
  Future<void> forget(String deviceId) async {
    if (isPinned(deviceId)) {
      await setPinned(deviceId, pinned: false);
    }

    final stored = _settings.get<Map<String, dynamic>>(lastUsedKey);
    if (stored == null || !stored.containsKey(deviceId)) {
      return;
    }

    await _settings.set(lastUsedKey, {...stored}..remove(deviceId));
  }

  /// Drops pins, last uses and "Keep both" answers of devices no longer
  /// paired, however they went: from here, from another device, or from
  /// ferret-cli.
  Future<void> keepOnly(Set<String> pairedIds) => _settings.keepOnlyPaired([
    pinnedKey,
    lastUsedKey,
    DeviceSuccessors.keptKey,
  ], pairedIds);

  /// Gives [newId] the pin and last use of [oldId], such as a phone that
  /// replaces an old one.
  Future<void> inherit(String oldId, {required String newId}) async {
    if (isPinned(oldId)) {
      await setPinned(newId, pinned: true);
    }

    if (lastUsed(oldId) case final used?) {
      await markUsed(newId, at: used);
    }

    await forget(oldId);
  }

  /// Whether a key one of these settings is stored under changed.
  static bool isOwnKey(String key) => key == pinnedKey || key == lastUsedKey;

  /// Connected devices first (one reconnecting keeps its place among them),
  /// then in each group the pinned ones, then the one used last, then, for
  /// offline ones, the one seen last, then by name. [lastUsed] replaces
  /// the stored last uses, such as ones that wait to move a row.
  List<DeviceStatus> arrange(
    List<DeviceStatus> devices, {
    Map<String, dynamic>? lastUsed,
  }) {
    final pinned = this.pinned;
    final stored =
        lastUsed ?? _settings.get<Map<String, dynamic>>(lastUsedKey) ?? {};

    int lastUsedOf(DeviceStatus status) => switch (stored[status.device.id]) {
      final int millis => millis,
      _ => 0,
    };
    int lastSeenOf(DeviceStatus status) => switch (isUp(status)) {
      true => 0,
      false => status.device.lastSeen?.millisecondsSinceEpoch ?? 0,
    };
    int rank(bool first) => switch (first) {
      true => 0,
      false => 1,
    };

    return [...devices]..sort((a, b) {
      final byUp = rank(isUp(a)).compareTo(rank(isUp(b)));
      if (byUp != 0) {
        return byUp;
      }

      final byPin = rank(
        pinned.contains(a.device.id),
      ).compareTo(rank(pinned.contains(b.device.id)));
      if (byPin != 0) {
        return byPin;
      }

      final byUse = lastUsedOf(b).compareTo(lastUsedOf(a));
      if (byUse != 0) {
        return byUse;
      }

      final bySeen = lastSeenOf(b).compareTo(lastSeenOf(a));
      if (bySeen != 0) {
        return bySeen;
      }

      return a.device.name.toLowerCase().compareTo(b.device.name.toLowerCase());
    });
  }

  static bool isUp(DeviceStatus status) =>
      status.isConnected || status.isReconnecting;

  /// Offline and not seen for [staleAfter], or never seen since pairing
  /// that long ago. A pinned device is never stale.
  bool isStale(DeviceStatus status, {DateTime? now}) {
    if (isUp(status) || isPinned(status.device.id)) {
      return false;
    }

    final seen = status.device.lastSeen ?? status.device.pairedAt;
    return (now ?? DateTime.now()).difference(seen) > staleAfter;
  }
}
