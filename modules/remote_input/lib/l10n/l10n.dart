import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:remote_input/l10n/generated/remote_input_localizations.dart';

export 'package:remote_input/l10n/generated/remote_input_localizations.dart';

extension RemoteInputL10n on BuildContext {
  RemoteInputLocalizations get remoteInputL10n =>
      RemoteInputLocalizations.of(this);
}

/// The strings in the language Ferret shows (Settings → Advanced, else the
/// system's), for notices and health built outside any widget.
RemoteInputLocalizations platformRemoteInputL10n() =>
    lookupRemoteInputLocalizations(
      AppLocale.pick(RemoteInputLocalizations.supportedLocales),
    );
