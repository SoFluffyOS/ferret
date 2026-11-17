import 'package:drop/feature/drop_feature.dart';
import 'package:drop/l10n/l10n.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The app side of Drop.
class DropFeatureUi extends FeatureUi {
  DropFeatureUi() : feature = DropFeature();

  @override
  final DropFeature feature;

  @override
  String get featureId => DropFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    DropLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.dropL10n.title;

  @override
  IconData get icon => LucideIcons.send;
}
