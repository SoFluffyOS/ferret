import 'package:drop/l10n/generated/drop_localizations.dart';
import 'package:drop/l10n/transfer_texts.dart';
import 'package:flutter/widgets.dart';

export 'package:drop/l10n/generated/drop_localizations.dart';
export 'package:drop/l10n/transfer_texts.dart';

extension DropL10n on BuildContext {
  DropLocalizations get dropL10n => DropLocalizations.of(this);

  TransferTexts get transferTexts => TransferTexts(dropL10n);
}
