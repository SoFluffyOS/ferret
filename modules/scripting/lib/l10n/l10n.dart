import 'package:flutter/widgets.dart';
import 'package:scripting/l10n/generated/scripting_localizations.dart';

export 'package:scripting/l10n/generated/scripting_localizations.dart';

extension ScriptingL10n on BuildContext {
  ScriptingLocalizations get scriptingL10n => ScriptingLocalizations.of(this);
}
