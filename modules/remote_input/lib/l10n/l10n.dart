import 'package:flutter/widgets.dart';
import 'package:remote_input/l10n/generated/remote_input_localizations.dart';

export 'package:remote_input/l10n/generated/remote_input_localizations.dart';

extension RemoteInputL10n on BuildContext {
  RemoteInputLocalizations get remoteInputL10n =>
      RemoteInputLocalizations.of(this);
}

/// The strings in the system language, for places without a [BuildContext]
/// such as notices and device health.
RemoteInputLocalizations platformRemoteInputL10n() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final supported = RemoteInputLocalizations.supportedLocales.any(
    (candidate) => candidate.languageCode == locale.languageCode,
  );
  if (supported) {
    return lookupRemoteInputLocalizations(Locale(locale.languageCode));
  }

  return lookupRemoteInputLocalizations(
    RemoteInputLocalizations.supportedLocales.first,
  );
}
