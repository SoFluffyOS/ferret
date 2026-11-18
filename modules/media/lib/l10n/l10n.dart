import 'package:flutter/widgets.dart';
import 'package:media/l10n/generated/media_localizations.dart';

export 'package:media/l10n/generated/media_localizations.dart';

extension MediaL10n on BuildContext {
  MediaLocalizations get mediaL10n => MediaLocalizations.of(this);
}

/// The strings in the system language, for places without a [BuildContext]
/// such as device health.
MediaLocalizations platformMediaL10n() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final supported = MediaLocalizations.supportedLocales.any(
    (candidate) => candidate.languageCode == locale.languageCode,
  );
  if (supported) {
    return lookupMediaLocalizations(Locale(locale.languageCode));
  }

  return lookupMediaLocalizations(MediaLocalizations.supportedLocales.first);
}
