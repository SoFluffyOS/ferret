import 'dart:ui';

import 'package:calls/l10n/generated/calls_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:calls/l10n/call_labels.dart';
export 'package:calls/l10n/generated/calls_localizations.dart';

extension CallsL10n on BuildContext {
  CallsLocalizations get callsL10n => CallsLocalizations.of(this);
}

/// The strings in the system language, for notices and health shown outside
/// any widget, falling back to English.
CallsLocalizations platformCallsL10n() {
  final locale = PlatformDispatcher.instance.locale;
  final supported = CallsLocalizations.supportedLocales.any(
    (candidate) => candidate.languageCode == locale.languageCode,
  );
  if (!supported) {
    return lookupCallsLocalizations(const Locale('en'));
  }

  return lookupCallsLocalizations(Locale(locale.languageCode));
}
