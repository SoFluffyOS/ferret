import 'package:flutter/widgets.dart';
import 'package:iphone/l10n/generated/iphone_localizations.dart';

export 'package:iphone/l10n/generated/iphone_localizations.dart';

extension IphoneL10n on BuildContext {
  IphoneLocalizations get iphoneL10n => IphoneLocalizations.of(this);
}
