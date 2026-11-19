import 'package:core/core.dart';

/// Which of Home's one-time tips were shown, and a way to see them again
/// for someone who comes back after months and forgot them.
class Tips {
  const Tips(this._settings);

  /// Settings keys that remember a tip was shown.
  static const copyDoneKey = 'shell.tip_copy_done';
  static const dragDoneKey = 'shell.tip_drag_done';
  static const pasteDoneKey = 'shell.tip_paste_done';

  /// When the tips were last asked for again, in milliseconds.
  static const againSinceKey = 'shell.tips_again_since';

  static const doneKeys = {copyDoneKey, dragDoneKey, pasteDoneKey};

  final SettingsStore _settings;

  bool get isCopyDone => _settings.get<bool>(copyDoneKey) ?? false;

  bool get isDragDone => _settings.get<bool>(dragDoneKey) ?? false;

  bool get isPasteDone => _settings.get<bool>(pasteDoneKey) ?? false;

  /// A tip goes away once the person does what it says. After
  /// [showAgain], only what they do from then on counts: yesterday's copy
  /// must not wave the tip off again at once.
  DateTime? get againSince => switch (_settings.get<int>(againSinceKey)) {
    final since? => DateTime.fromMillisecondsSinceEpoch(since),
    null => null,
  };

  /// Whether something that happened at [at] is the person trying a tip.
  bool countsAsTried(DateTime? at) {
    final since = againSince;
    if (since == null) {
      return true;
    }

    return at != null && at.isAfter(since);
  }

  Future<void> finish(String doneKey) => _settings.set(doneKey, true);

  /// Brings every tip back, one at a time as before.
  Future<void> showAgain({DateTime? now}) async {
    await _settings.set(
      againSinceKey,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
    for (final doneKey in doneKeys) {
      await _settings.set(doneKey, false);
    }
  }
}
