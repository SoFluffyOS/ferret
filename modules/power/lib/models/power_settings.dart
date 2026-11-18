import 'package:core/core.dart';

/// The power-ups' settings, stored under `power.*`.
class PowerSettings {
  const PowerSettings(this._store);

  static const shizukuEnabledKey = 'power.shizuku_enabled';
  static const rootEnabledKey = 'power.root_enabled';
  static const cardDismissedKey = 'power.card_dismissed';

  final SettingsStore _store;

  /// The user let Ferret use Shizuku. Nothing runs through it otherwise.
  bool get shizukuEnabled => _store.get<bool>(shizukuEnabledKey) ?? false;

  /// The user let Ferret use root. `su` is never run otherwise.
  bool get rootEnabled => _store.get<bool>(rootEnabledKey) ?? false;

  /// The user answered "Not now" to the home card's offer.
  bool get cardDismissed => _store.get<bool>(cardDismissedKey) ?? false;

  Future<void> setShizukuEnabled(bool value) =>
      _store.set(shizukuEnabledKey, value);

  Future<void> setRootEnabled(bool value) => _store.set(rootEnabledKey, value);

  Future<void> setCardDismissed(bool value) =>
      _store.set(cardDismissedKey, value);

  /// Fires with the key of each power-up setting that changed.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('power.'));
}
