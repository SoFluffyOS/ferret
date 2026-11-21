import 'package:core/core.dart';

/// Whether Home's "Do more" card was waved off. It stays away until a
/// feature that wasn't offered at the time has something to offer; then it
/// comes back, until it is waved off again. Settings → Do more keeps every
/// offer either way.
class OffersDismissal {
  const OffersDismissal(this._settings);

  /// The features that were on offer when the card was last waved off.
  static const dismissedKey = 'shell.offers_dismissed';

  final SettingsStore _settings;

  Set<String>? get _dismissed => switch (_settings.get<List<Object?>>(
    dismissedKey,
  )) {
    final ids? => {
      for (final id in ids)
        if (id is String) id,
    },
    null => null,
  };

  /// Whether the card stays hidden while [offered] features have offers.
  bool hides(Set<String> offered) {
    final dismissed = _dismissed;
    return dismissed != null && dismissed.containsAll(offered);
  }

  /// Hides the card for [offered] and for anything waved off before.
  Future<void> dismiss(Set<String> offered) => _settings.set(dismissedKey, [
    ...{...?_dismissed, ...offered},
  ]);
}
