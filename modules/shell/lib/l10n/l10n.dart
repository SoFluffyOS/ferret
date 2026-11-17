import 'package:flutter/widgets.dart';
import 'package:shell/l10n/generated/shell_localizations.dart';

export 'package:shell/l10n/generated/shell_localizations.dart';

extension ShellL10n on BuildContext {
  ShellLocalizations get shellL10n => ShellLocalizations.of(this);
}
