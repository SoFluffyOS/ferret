import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/generated/iphone_localizations.dart';

export 'package:iphone/l10n/generated/iphone_localizations.dart';

extension IphoneL10n on BuildContext {
  IphoneLocalizations get iphoneL10n => IphoneLocalizations.of(this);
}

/// The strings in the language Ferret shows (Settings → Advanced, else the
/// system's), for notices and health built outside any widget.
IphoneLocalizations platformIphoneL10n() => lookupIphoneLocalizations(
  AppLocale.pick(IphoneLocalizations.supportedLocales),
);
