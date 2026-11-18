import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/generated/handoff_localizations.dart';

export 'package:handoff/l10n/generated/handoff_localizations.dart';

extension HandoffL10n on BuildContext {
  HandoffLocalizations get handoffL10n => HandoffLocalizations.of(this);
}

/// Handoff's strings outside a widget, such as for notices, in the system
/// language when Handoff has it and English otherwise.
HandoffLocalizations handoffL10nForSystem() {
  final locale = PlatformDispatcher.instance.locale;
  final supported = HandoffLocalizations.supportedLocales.any(
    (candidate) => candidate.languageCode == locale.languageCode,
  );
  if (supported) {
    return lookupHandoffLocalizations(Locale(locale.languageCode));
  }

  return lookupHandoffLocalizations(const Locale('en'));
}
