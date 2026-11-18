import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/feature/mirroring_feature.dart';
import 'package:mirroring/l10n/l10n.dart';

/// The app side of Screen mirroring.
class MirroringFeatureUi extends FeatureUi {
  MirroringFeatureUi() : feature = MirroringFeature();

  @override
  final MirroringFeature feature;

  @override
  String get featureId => MirroringFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    MirroringLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.mirroringL10n.title;

  @override
  IconData get icon => LucideIcons.screenShare;
}
