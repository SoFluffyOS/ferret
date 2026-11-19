import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:media/l10n/generated/media_localizations.dart';

export 'package:media/l10n/generated/media_localizations.dart';

extension MediaL10n on BuildContext {
  MediaLocalizations get mediaL10n => MediaLocalizations.of(this);
}

/// The strings in the language Ferret shows (Settings → Advanced, else the
/// system's), for notices and health built outside any widget.
MediaLocalizations platformMediaL10n() => lookupMediaLocalizations(
  AppLocale.pick(MediaLocalizations.supportedLocales),
);
