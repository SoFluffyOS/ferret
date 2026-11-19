import 'package:core/core.dart';

/// Whether Ferret starts when the phone starts. Off until the person says
/// yes: the Stay connected card asks once and the answer is kept.
class BootChoice {
  const BootChoice(this._settings);

  static const startKey = 'system.start_on_boot';

  /// Null on an install that never ran a Ferret with the question, false
  /// while the question waits, true once it was answered (or never needed
  /// asking).
  static const answeredKey = 'system.start_on_boot_answered';

  final SettingsStore _settings;

  bool get startsOnBoot => _settings.get<bool>(startKey) ?? false;

  /// The question is still to be asked.
  bool get needsAnswer => _settings.get<bool>(answeredKey) == false;

  /// Sorts out an install that hasn't seen the question yet, once. One
  /// from before it ([hadDevices]: it was already paired) started with the
  /// phone unless that was turned off: it keeps what it had and is never
  /// asked. A new one starts off and is asked.
  Future<void> adopt({required bool hadDevices}) async {
    if (_settings.get<bool>(answeredKey) != null) {
      return;
    }

    final chose = _settings.get<bool>(startKey) != null;
    if (hadDevices && !chose) {
      await _settings.set(startKey, true);
    }

    await _settings.set(answeredKey, hadDevices || chose);
  }

  /// The person's answer, from the card or from the switch in Settings.
  Future<void> answer({required bool start}) async {
    await _settings.set(startKey, start);
    await _settings.set(answeredKey, true);
  }
}
