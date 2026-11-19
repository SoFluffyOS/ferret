import 'package:core/core.dart';

/// The scripting feature's choices, under `scripting.*`.
class ScriptingSettings {
  const ScriptingSettings(this._store);

  /// Device id to true when scripts on that device may show notices here.
  static const notifyKey = 'scripting.notify_allowed';

  final SettingsStore _store;

  Stream<String> get changes => _store.changes.where((key) => key == notifyKey);

  /// Off until the person turns it on for [deviceId]: a script anywhere
  /// else can't put words on this screen by default.
  bool allowsNotices(String deviceId) => _choices()[deviceId] == true;

  Future<void> setAllowsNotices(String deviceId, {required bool allowed}) =>
      _store.set(notifyKey, {..._choices(), deviceId: allowed});

  Map<String, Object?> _choices() => switch (_store.get<Object?>(notifyKey)) {
    final Map<String, Object?> stored => stored,
    _ => const {},
  };
}
