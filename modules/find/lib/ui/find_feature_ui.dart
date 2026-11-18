import 'package:feature_kit/feature_kit.dart';
import 'package:find/feature/find_feature.dart';
import 'package:find/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The app side of Find my device.
class FindFeatureUi extends FeatureUi {
  FindFeatureUi() : feature = FindFeature();

  @override
  final FindFeature feature;

  @override
  String get featureId => FindFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    FindLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.findL10n.title;

  @override
  IconData get icon => LucideIcons.radar;
}
