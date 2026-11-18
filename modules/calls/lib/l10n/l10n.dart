import 'package:calls/l10n/generated/calls_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:calls/l10n/generated/calls_localizations.dart';

extension CallsL10n on BuildContext {
  CallsLocalizations get callsL10n => CallsLocalizations.of(this);
}
