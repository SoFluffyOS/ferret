import 'package:flutter/widgets.dart';
import 'package:power/l10n/generated/power_localizations.dart';

export 'package:power/l10n/generated/power_localizations.dart';

extension PowerL10n on BuildContext {
  PowerLocalizations get powerL10n => PowerLocalizations.of(this);
}
