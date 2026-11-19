import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';

/// The strings of the shell and every feature, for each view's app.
List<LocalizationsDelegate<Object?>> appLocalizationsDelegates(
  List<FeatureUi> features,
) => [
  ...AppLocale.debugLeadingDelegates,
  ShellLocalizations.delegate,
  for (final feature in features) ...feature.localizationsDelegates,
  GlobalWidgetsLocalizations.delegate,
];

/// The language picked in Settings → Advanced, or null to follow the
/// system. Rebuilds the caller when the choice changes.
Locale? chosenLocale(BuildContext context) =>
    context.select<ValueNotifier<Locale?>?, Locale?>(
      (chosen) => chosen?.value,
    );
