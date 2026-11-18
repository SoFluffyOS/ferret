import 'package:find/l10n/generated/find_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:find/l10n/generated/find_localizations.dart';

extension FindL10n on BuildContext {
  FindLocalizations get findL10n => FindLocalizations.of(this);
}
