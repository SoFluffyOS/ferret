import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:shell/services/device_preferences.dart';

/// A device that was just paired and looks like it replaces an older one:
/// the same name and platform, paired after the old one was last seen.
class Successor {
  const Successor({required this.replacement, required this.old});

  final TrustedDevice replacement;
  final TrustedDevice old;
}

/// Finds paired devices that probably replace an older one, such as a phone
/// that was reset or swapped and paired again: it gets a new identity, so
/// Ferret sees a second "Pixel 7" next to one that will never come back.
class DeviceSuccessors {
  const DeviceSuccessors(this._settings);

  /// Ids of new devices the user said to keep next to their namesake.
  static const keptKey = 'shell.kept_namesakes';

  /// How long after pairing a device is still asked about.
  static const askFor = Duration(days: 14);

  final SettingsStore _settings;

  Set<String> get _kept => {
    for (final id in _settings.get<List<Object?>>(keptKey) ?? const [])
      if (id case final String deviceId) deviceId,
  };

  /// Each recently paired device with the older namesake it replaces. Each
  /// old device is offered once, for its newest namesake.
  List<Successor> find(List<DeviceStatus> devices, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final kept = _kept;
    final newestFirst = [...devices]
      ..sort((a, b) => b.device.pairedAt.compareTo(a.device.pairedAt));
    final taken = <String>{};
    final found = <Successor>[];

    for (final candidate in newestFirst) {
      final replacement = candidate.device;
      final isRecent = at.difference(replacement.pairedAt) < askFor;
      if (!isRecent || kept.contains(replacement.id)) {
        continue;
      }

      if (_oldNamesake(replacement, devices, taken) case final old?) {
        taken.addAll({old.id, replacement.id});
        found.add(Successor(replacement: replacement, old: old));
      }
    }

    return found;
  }

  /// Leaves [replacementId] next to its namesake for good.
  Future<void> keepBoth(String replacementId) => _settings.set(keptKey, [
    ...{..._kept, replacementId},
  ]);

  TrustedDevice? _oldNamesake(
    TrustedDevice replacement,
    List<DeviceStatus> devices,
    Set<String> taken,
  ) {
    TrustedDevice? best;
    for (final status in devices) {
      final old = status.device;
      final matches =
          old.id != replacement.id &&
          !taken.contains(old.id) &&
          !DevicePreferences.isUp(status) &&
          old.platform == replacement.platform &&
          _sameName(old.ownName, replacement.ownName) &&
          old.pairedAt.isBefore(replacement.pairedAt) &&
          !(old.lastSeen ?? old.pairedAt).isAfter(replacement.pairedAt);
      if (!matches) {
        continue;
      }

      final seen = old.lastSeen ?? old.pairedAt;
      if (best == null || seen.isAfter(best.lastSeen ?? best.pairedAt)) {
        best = old;
      }
    }

    return best;
  }

  static bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();
}
