import 'package:core/core.dart';

/// Settings that keep something per paired device, keyed by device id.
extension PairedSettings on SettingsStore {
  /// Drops every device but [deviceIds] from the settings under [keys]:
  /// a list of ids, or a map from id to a choice. Others are left alone.
  Future<void> keepOnlyPaired(
    Iterable<String> keys,
    Set<String> deviceIds,
  ) async {
    for (final key in keys) {
      switch (get<Object>(key)) {
        case final List<Object?> ids:
          final kept = [
            for (final id in ids)
              if (id is! String || deviceIds.contains(id)) id,
          ];
          if (kept.length != ids.length) {
            await set(key, kept);
          }
        case final Map<Object?, Object?> choices:
          final kept = {
            for (final MapEntry(:key, :value) in choices.entries)
              if (key is String && deviceIds.contains(key)) key: value,
          };
          if (kept.length != choices.length) {
            await set(key, kept);
          }
      }
    }
  }
}
