import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/generated/handoff_localizations.dart';

export 'package:handoff/l10n/generated/handoff_localizations.dart';

extension HandoffL10n on BuildContext {
  HandoffLocalizations get handoffL10n => HandoffLocalizations.of(this);
}

/// Handoff's strings outside a widget, such as for notices, in the language
/// Ferret shows (Settings → Advanced, else the system's).
HandoffLocalizations handoffL10nForSystem() => lookupHandoffLocalizations(
  AppLocale.pick(HandoffLocalizations.supportedLocales),
);
