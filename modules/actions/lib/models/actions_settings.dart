import 'package:actions/models/action_record.dart';
import 'package:actions/models/custom_action.dart';
import 'package:core/core.dart';

/// Computer actions' settings, stored under `actions.*`.
class ActionsSettings {
  const ActionsSettings(this._store);

  static const enabledKey = 'actions.enabled';
  static const customKey = 'actions.custom';

  /// A map from a device's id to the grant ids it may run without asking.
  static const allowedKey = 'actions.allowed';
  static const historyKey = 'actions.history';

  /// The phones whose leaving locks this computer, by device id.
  static const lockWhenGoneKey = 'actions.lock_when_gone';

  /// How many minutes a phone is gone before this computer locks.
  static const lockAfterKey = 'actions.lock_after_minutes';

  static const lockAfterDefault = 2;
  static const lockAfterMin = 1;
  static const lockAfterMax = 10;

  /// How many past runs the history keeps.
  static const historyLength = 20;

  final SettingsStore _store;

  /// Devices may ask this computer to run actions. On by default: each one
  /// still needs the owner's yes the first time, for each action.
  bool get enabled => _store.get<bool>(enabledKey) ?? true;

  /// The owner's own actions, in the order they were added.
  List<CustomAction> get custom => [
    for (final json in _store.get<List<Object?>>(customKey) ?? const [])
      ?CustomAction.fromJson(json),
  ];

  /// What [deviceId] may run without asking, as grant ids.
  List<String> allowedFor(String deviceId) => switch (_allowed[deviceId]) {
    final List<Object?> grants => [
      for (final id in grants)
        if (id case final String grantId) grantId,
    ],
    _ => const [],
  };

  bool isAllowed(String deviceId, String grantId) =>
      allowedFor(deviceId).contains(grantId);

  /// The phones whose leaving locks this computer. Off for every phone
  /// until the owner turns it on.
  List<String> get lockWhenGone => [
    for (final id in _store.get<List<Object?>>(lockWhenGoneKey) ?? const [])
      if (id case final String deviceId) deviceId,
  ];

  bool locksWhenGone(String deviceId) => lockWhenGone.contains(deviceId);

  /// Minutes a phone must stay gone, from [lockAfterMin] to [lockAfterMax].
  int get lockAfterMinutes => switch (_store.get<int>(lockAfterKey)) {
    final int minutes => minutes.clamp(lockAfterMin, lockAfterMax),
    null => lockAfterDefault,
  };

  /// Past runs, newest first.
  List<ActionRecord> get history => [
    for (final json in _store.get<List<Object?>>(historyKey) ?? const [])
      ?ActionRecord.fromJson(json),
  ];

  Future<void> setEnabled(bool value) => _store.set(enabledKey, value);

  Future<void> setCustom(List<CustomAction> actions) =>
      _store.set(customKey, [for (final action in actions) action.toJson()]);

  Future<void> setAllowed(
    String deviceId,
    String grantId, {
    required bool allowed,
  }) {
    final grants = [
      for (final id in allowedFor(deviceId))
        if (id != grantId) id,
      if (allowed) grantId,
    ];

    return _store.set(allowedKey, {
      for (final MapEntry(:key, :value) in _allowed.entries)
        if (key != deviceId) key: value,
      if (grants.isNotEmpty) deviceId: grants,
    });
  }

  /// Takes [grantId] back from every device, such as when its command
  /// changed and no longer is what they were allowed to run.
  Future<void> revokeEverywhere(String grantId) => _store.set(allowedKey, {
    for (final deviceId in _allowed.keys)
      if (allowedFor(deviceId).where((id) => id != grantId).toList()
          case final left when left.isNotEmpty)
        deviceId: left,
  });

  Future<void> setLocksWhenGone(String deviceId, {required bool locks}) =>
      _store.set(lockWhenGoneKey, [
        for (final id in lockWhenGone)
          if (id != deviceId) id,
        if (locks) deviceId,
      ]);

  Future<void> setLockAfterMinutes(int minutes) =>
      _store.set(lockAfterKey, minutes.clamp(lockAfterMin, lockAfterMax));

  Future<void> addRecord(ActionRecord record) => _store.set(historyKey, [
    record.toJson(),
    for (final past in history.take(historyLength - 1)) past.toJson(),
  ]);

  Future<void> clearHistory() => _store.set(historyKey, const <Object?>[]);

  /// Fires with the key of each setting that changes.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('actions.'));

  Map<String, Object?> get _allowed =>
      switch (_store.get<Map<Object?, Object?>>(
        allowedKey,
      )) {
        final Map<Object?, Object?> stored => {
          for (final MapEntry(:key, :value) in stored.entries)
            if (key case final String deviceId) deviceId: value,
        },
        null => const {},
      };
}
