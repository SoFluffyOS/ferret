import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/feature/iphone_feature.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The app side of iPhone.
class IphoneFeatureUi extends FeatureUi {
  IphoneFeatureUi() : feature = IphoneFeature();

  @override
  final IphoneFeature feature;

  @override
  String get featureId => IphoneFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    IphoneLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.iphoneL10n.title;

  @override
  IconData get icon => LucideIcons.bluetooth;
}
