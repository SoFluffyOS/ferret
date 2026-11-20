import 'package:flutter/widgets.dart';
import 'package:local_shelf/l10n/generated/shelf_localizations.dart';

export 'package:local_shelf/l10n/generated/shelf_localizations.dart';

extension ShelfL10n on BuildContext {
  ShelfLocalizations get shelfL10n => ShelfLocalizations.of(this);
}
