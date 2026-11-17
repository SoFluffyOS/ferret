import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/generated/handoff_localizations.dart';

export 'package:handoff/l10n/generated/handoff_localizations.dart';

extension HandoffL10n on BuildContext {
  HandoffLocalizations get handoffL10n => HandoffLocalizations.of(this);
}
