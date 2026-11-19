import 'package:feature_kit/feature_kit.dart';
import 'package:find/l10n/generated/find_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:find/l10n/generated/find_localizations.dart';

extension FindL10n on BuildContext {
  FindLocalizations get findL10n => FindLocalizations.of(this);
}

/// The strings in the language Ferret shows (Settings → Advanced, else the
/// system's), for notices and health built outside any widget.
FindLocalizations platformFindL10n() =>
    lookupFindLocalizations(AppLocale.pick(FindLocalizations.supportedLocales));
