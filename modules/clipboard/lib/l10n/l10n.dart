import 'package:clipboard/l10n/generated/clipboard_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:clipboard/l10n/generated/clipboard_localizations.dart';

extension ClipboardL10n on BuildContext {
  ClipboardLocalizations get clipboardL10n => ClipboardLocalizations.of(this);
}
