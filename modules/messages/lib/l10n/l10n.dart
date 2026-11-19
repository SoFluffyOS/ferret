import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/generated/messages_localizations.dart';

export 'package:messages/l10n/generated/messages_localizations.dart';
export 'package:messages/l10n/message_labels.dart';

extension MessagesL10n on BuildContext {
  MessagesLocalizations get messagesL10n => MessagesLocalizations.of(this);
}

/// The strings in the language Ferret shows (Settings → Advanced, else the
/// system's), for notices and health built outside any widget.
MessagesLocalizations platformMessagesL10n() => lookupMessagesLocalizations(
  AppLocale.pick(MessagesLocalizations.supportedLocales),
);
