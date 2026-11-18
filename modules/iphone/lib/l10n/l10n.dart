import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/generated/iphone_localizations.dart';

export 'package:iphone/l10n/generated/iphone_localizations.dart';

extension IphoneL10n on BuildContext {
  IphoneLocalizations get iphoneL10n => IphoneLocalizations.of(this);
}

/// The strings in the system language, for places without a [BuildContext]
/// such as notices.
IphoneLocalizations platformIphoneL10n() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final supported = IphoneLocalizations.supportedLocales.any(
    (candidate) => candidate.languageCode == locale.languageCode,
  );
  if (supported) {
    return lookupIphoneLocalizations(Locale(locale.languageCode));
  }

  return lookupIphoneLocalizations(IphoneLocalizations.supportedLocales.first);
}
