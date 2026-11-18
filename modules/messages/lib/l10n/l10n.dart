import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:messages/l10n/generated/messages_localizations.dart';

export 'package:messages/l10n/generated/messages_localizations.dart';
export 'package:messages/l10n/message_labels.dart';

extension MessagesL10n on BuildContext {
  MessagesLocalizations get messagesL10n => MessagesLocalizations.of(this);
}

/// The strings in the system language, for notices and health shown outside
/// any widget, falling back to English.
MessagesLocalizations platformMessagesL10n() {
  final locale = PlatformDispatcher.instance.locale;
  final supported = MessagesLocalizations.supportedLocales.any(
    (candidate) => candidate.languageCode == locale.languageCode,
  );
  if (!supported) {
    return lookupMessagesLocalizations(const Locale('en'));
  }

  return lookupMessagesLocalizations(Locale(locale.languageCode));
}
