import 'package:calls/l10n/generated/calls_localizations.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

export 'package:calls/l10n/call_labels.dart';
export 'package:calls/l10n/generated/calls_localizations.dart';

extension CallsL10n on BuildContext {
  CallsLocalizations get callsL10n => CallsLocalizations.of(this);
}

/// The strings in the language Ferret shows (Settings → Advanced, else the
/// system's), for notices and health built outside any widget.
CallsLocalizations platformCallsL10n() => lookupCallsLocalizations(
  AppLocale.pick(CallsLocalizations.supportedLocales),
);
