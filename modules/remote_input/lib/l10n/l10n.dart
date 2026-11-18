import 'package:flutter/widgets.dart';
import 'package:remote_input/l10n/generated/remote_input_localizations.dart';

export 'package:remote_input/l10n/generated/remote_input_localizations.dart';

extension RemoteInputL10n on BuildContext {
  RemoteInputLocalizations get remoteInputL10n =>
      RemoteInputLocalizations.of(this);
}
