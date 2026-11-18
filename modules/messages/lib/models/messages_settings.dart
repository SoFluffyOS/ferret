import 'package:core/core.dart';

/// The messages feature's settings, stored under `messages.*`.
class MessagesSettings {
  const MessagesSettings(this._store);

  static const enabledKey = 'messages.enabled';
  static const notifyKey = 'messages.notify';

  final SettingsStore _store;

  /// On a phone: the person turned Messages on, so paired computers may read
  /// and send its texts. Off until they do, since it needs SMS access.
  bool get enabled => _store.get<bool>(enabledKey) ?? false;

  /// On a computer: new texts show as notices with Reply.
  bool get notify => _store.get<bool>(notifyKey) ?? true;

  Future<void> setEnabled(bool value) => _store.set(enabledKey, value);

  Future<void> setNotify(bool value) => _store.set(notifyKey, value);

  /// Fires with the key of each messages setting that changed.
  Stream<String> get changes => _store.changes.where(owns);

  static bool owns(String key) => key.startsWith('messages.');
}
