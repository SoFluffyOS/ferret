import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:power/feature/power_feature.dart';
import 'package:power/l10n/l10n.dart';

/// The app side of Power-ups.
class PowerFeatureUi extends FeatureUi {
  PowerFeatureUi() : feature = PowerFeature();

  @override
  final PowerFeature feature;

  @override
  String get featureId => PowerFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    PowerLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.powerL10n.title;

  @override
  IconData get icon => LucideIcons.zap;
}
