import 'package:core/core.dart';
import 'package:mirroring/models/mirror_record.dart';

/// Screen mirroring's settings, stored under `mirroring.*`.
class MirroringSettings {
  const MirroringSettings(this._store);

  static const enabledKey = 'mirroring.enabled';
  static const historyKey = 'mirroring.history';
  static const actualSizeKey = 'mirroring.actual_size';
  static const moreWaysKey = 'mirroring.more_ways';

  /// How many past times of mirroring the history keeps.
  static const historyLength = 20;

  final SettingsStore _store;

  /// Paired computers may ask to see this screen. On by default: Android
  /// still asks its owner every single time.
  bool get enabled => _store.get<bool>(enabledKey) ?? true;

  /// Past times of mirroring on this device, newest first.
  List<MirrorRecord> get history => [
    for (final json in _store.get<List<Object?>>(historyKey) ?? const [])
      ?MirrorRecord.fromJson(json),
  ];

  /// The mirror page shows one phone pixel per screen pixel instead of
  /// fitting the picture to the window.
  bool get actualSize => _store.get<bool>(actualSizeKey) ?? false;

  /// This computer also shows screens that arrive another way than
  /// Ferret's own connection, such as over a cable. Off until asked for:
  /// those ways are experimental, and some listen on the network.
  bool get moreWays => _store.get<bool>(moreWaysKey) ?? false;

  Future<void> setMoreWays(bool value) => _store.set(moreWaysKey, value);

  Future<void> setEnabled(bool value) => _store.set(enabledKey, value);

  Future<void> setActualSize(bool value) => _store.set(actualSizeKey, value);

  Future<void> addRecord(MirrorRecord record) => _store.set(historyKey, [
    record.toJson(),
    for (final past in history.take(historyLength - 1)) past.toJson(),
  ]);

  Future<void> clearHistory() => _store.set(historyKey, const <Object?>[]);

  /// Fires with the key of each setting that changes.
  Stream<String> get changes =>
      _store.changes.where((key) => key.startsWith('mirroring.'));
}
