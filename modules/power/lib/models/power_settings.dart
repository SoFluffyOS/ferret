import 'package:core/core.dart';

/// The power-ups' settings, stored under `power.*`.
class PowerSettings {
  const PowerSettings(this._store);

  static const shizukuEnabledKey = 'power.shizuku_enabled';
  static const rootEnabledKey = 'power.root_enabled';

  final SettingsStore _store;

  /// The user let Ferret use Shizuku. Nothing runs through it otherwise.
  bool get shizukuEnabled => _store.get<bool>(shizukuEnabledKey) ?? false;

  /// The user let Ferret use root. `su` is never run otherwise.
  bool get rootEnabled => _store.get<bool>(rootEnabledKey) ?? false;

  Future<void> setShizukuEnabled(bool value) =>
      _store.set(shizukuEnabledKey, value);

  Future<void> setRootEnabled(bool value) => _store.set(rootEnabledKey, value);

  /// Fires with the key of each power-up setting that changed.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('power.'));
}
