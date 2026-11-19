import 'package:core/core.dart';
import 'package:shell/services/shared_computer.dart';

/// Whether private things from each paired device, such as notifications,
/// texts, callers and copied text, show on this computer's screen.
///
/// On unless the person turned it off for that device, and off by default
/// on a computer other accounts run Ferret on (see [SharedComputer]), where
/// someone else may be at the screen.
class PrivatePreviews {
  PrivatePreviews(this.settings);

  /// Setting: device id to true (shown) or false (hidden), as chosen.
  static const choicesKey = 'privacy.previews';

  final SettingsStore settings;

  static bool isOwnKey(String key) =>
      key == choicesKey || key == SharedComputer.sharedKey;

  /// Whether nothing was chosen yet and previews show.
  bool get shownByDefault => !SharedComputer(settings).isShared;

  /// Whether the person chose for [deviceId], rather than the default.
  bool hasChoiceFor(String deviceId) => _choices()[deviceId] is bool;

  bool showsFrom(String deviceId) => switch (_choices()[deviceId]) {
    final bool chosen => chosen,
    _ => shownByDefault,
  };

  Future<void> setShows(String deviceId, {required bool shows}) async {
    await settings.set(choicesKey, {..._choices(), deviceId: shows});
  }

  Map<String, Object?> _choices() => switch (settings.get<Object?>(
    choicesKey,
  )) {
    final Map<String, Object?> stored => stored,
    _ => const {},
  };
}
