import 'package:find/l10n/generated/find_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:find/l10n/generated/find_localizations.dart';

extension FindL10n on BuildContext {
  FindLocalizations get findL10n => FindLocalizations.of(this);
}

/// The strings in the system language, for places without a [BuildContext]
/// such as notices and device health.
FindLocalizations platformFindL10n() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final supported = FindLocalizations.supportedLocales.any(
    (candidate) => candidate.languageCode == locale.languageCode,
  );
  if (supported) {
    return lookupFindLocalizations(Locale(locale.languageCode));
  }

  return lookupFindLocalizations(FindLocalizations.supportedLocales.first);
}
