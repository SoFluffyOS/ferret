import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/generated/mirroring_localizations.dart';

export 'package:mirroring/l10n/generated/mirroring_localizations.dart';

extension MirroringL10n on BuildContext {
  MirroringLocalizations get mirroringL10n => MirroringLocalizations.of(this);
}
