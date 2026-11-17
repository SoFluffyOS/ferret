import 'package:flutter/widgets.dart';
import 'package:media/l10n/generated/media_localizations.dart';

export 'package:media/l10n/generated/media_localizations.dart';

extension MediaL10n on BuildContext {
  MediaLocalizations get mediaL10n => MediaLocalizations.of(this);
}
