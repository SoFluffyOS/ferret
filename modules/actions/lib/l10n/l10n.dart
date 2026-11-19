import 'package:actions/l10n/generated/actions_localizations.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

export 'package:actions/l10n/action_texts.dart';
export 'package:actions/l10n/generated/actions_localizations.dart';

extension ActionsL10n on BuildContext {
  ActionsLocalizations get actionsL10n => ActionsLocalizations.of(this);
}

/// The strings in the language Ferret shows (Settings → Advanced, else the
/// system's), for notices and health built outside any widget.
ActionsLocalizations platformActionsL10n() => lookupActionsLocalizations(
  AppLocale.pick(ActionsLocalizations.supportedLocales),
);
