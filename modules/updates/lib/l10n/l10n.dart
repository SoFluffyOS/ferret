import 'package:flutter/widgets.dart';
import 'package:updates/l10n/generated/updates_localizations.dart';

export 'package:updates/l10n/generated/updates_localizations.dart';

extension UpdatesL10n on BuildContext {
  UpdatesLocalizations get updatesL10n => UpdatesLocalizations.of(this);
}
