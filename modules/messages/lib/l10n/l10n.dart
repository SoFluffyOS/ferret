import 'package:flutter/widgets.dart';
import 'package:messages/l10n/generated/messages_localizations.dart';

export 'package:messages/l10n/generated/messages_localizations.dart';

extension MessagesL10n on BuildContext {
  MessagesLocalizations get messagesL10n => MessagesLocalizations.of(this);
}
