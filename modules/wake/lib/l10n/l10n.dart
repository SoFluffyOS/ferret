import 'package:flutter/widgets.dart';
import 'package:wake/l10n/generated/wake_localizations.dart';

export 'package:wake/l10n/generated/wake_localizations.dart';

extension WakeL10n on BuildContext {
  WakeLocalizations get wakeL10n => WakeLocalizations.of(this);
}
