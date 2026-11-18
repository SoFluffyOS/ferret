import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/generated/mirroring_localizations.dart';

export 'package:mirroring/l10n/generated/mirroring_localizations.dart';

extension MirroringL10n on BuildContext {
  MirroringLocalizations get mirroringL10n => MirroringLocalizations.of(this);
}

/// The strings in the system language, for places without a [BuildContext]
/// such as the phone's notices and device health.
MirroringLocalizations platformMirroringL10n() {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final supported = MirroringLocalizations.supportedLocales.any(
    (candidate) => candidate.languageCode == locale.languageCode,
  );
  if (supported) {
    return lookupMirroringLocalizations(Locale(locale.languageCode));
  }

  return lookupMirroringLocalizations(
    MirroringLocalizations.supportedLocales.first,
  );
}
