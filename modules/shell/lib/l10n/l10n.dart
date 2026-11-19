import 'package:flutter/widgets.dart';
import 'package:shell/l10n/generated/shell_localizations.dart';

export 'package:shell/l10n/generated/shell_localizations.dart';
export 'package:shell/l10n/last_seen_text.dart';
export 'package:shell/l10n/local_names.dart';
export 'package:shell/l10n/settings_values.dart';

extension ShellL10n on BuildContext {
  ShellLocalizations get shellL10n => ShellLocalizations.of(this);
}
