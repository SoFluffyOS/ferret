import 'package:drop/l10n/generated/drop_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:drop/l10n/generated/drop_localizations.dart';

extension DropL10n on BuildContext {
  DropLocalizations get dropL10n => DropLocalizations.of(this);
}
