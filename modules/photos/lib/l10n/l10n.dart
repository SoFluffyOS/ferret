import 'package:flutter/widgets.dart';
import 'package:photos/l10n/generated/photos_localizations.dart';

export 'package:photos/l10n/generated/photos_localizations.dart';

extension PhotosL10n on BuildContext {
  PhotosLocalizations get photosL10n => PhotosLocalizations.of(this);
}
