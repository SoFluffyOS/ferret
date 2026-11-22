import 'package:core/core.dart';

/// The update check's settings, under `updates.*`.
extension type const UpdateSettings(SettingsStore store) {
  static const checkKey = 'updates.check';
  static const betasKey = 'updates.betas';
  static const lastCheckKey = 'updates.last_check';
  static const dismissedKey = 'updates.dismissed';

  /// Whether Ferret checks GitHub once a day. On unless turned off.
  bool get checks => store.get<bool>(checkKey) ?? true;

  Future<void> setChecks(bool value) => store.set(checkKey, value);

  /// Whether test versions (pre-releases) count. Off unless turned on.
  bool get betas => store.get<bool>(betasKey) ?? false;

  Future<void> setBetas(bool value) => store.set(betasKey, value);

  /// When GitHub last answered, or null before the first check.
  DateTime? get lastCheck => switch (store.get<int>(lastCheckKey)) {
    final millis? => DateTime.fromMillisecondsSinceEpoch(millis),
    null => null,
  };

  Future<void> setLastCheck(DateTime at) =>
      store.set(lastCheckKey, at.millisecondsSinceEpoch);

  /// The release tag whose line the person closed with its ✕.
  String? get dismissed => store.get<String>(dismissedKey);

  Future<void> setDismissed(String? tag) => store.set(dismissedKey, tag);
}
