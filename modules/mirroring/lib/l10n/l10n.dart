import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
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

/// This computer, as strings name it: "this Mac", "this PC", or "this
/// computer" on Linux. Pass [name] as a string's `here`.
abstract final class MirrorHere {
  static String get name => defaultTargetPlatform.name;
}
