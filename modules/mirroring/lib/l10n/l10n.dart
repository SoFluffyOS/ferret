import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/generated/mirroring_localizations.dart';

export 'package:mirroring/l10n/generated/mirroring_localizations.dart';

extension MirroringL10n on BuildContext {
  MirroringLocalizations get mirroringL10n => MirroringLocalizations.of(this);
}

/// The strings in the language Ferret shows (Settings → Advanced, else the
/// system's), for notices and health built outside any widget.
MirroringLocalizations platformMirroringL10n() => lookupMirroringLocalizations(
  AppLocale.pick(MirroringLocalizations.supportedLocales),
);
