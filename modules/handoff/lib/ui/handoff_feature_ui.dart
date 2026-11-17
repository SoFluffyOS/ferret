import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/feature/handoff_feature.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The app side of Handoff.
class HandoffFeatureUi extends FeatureUi {
  HandoffFeatureUi() : feature = HandoffFeature();

  @override
  final HandoffFeature feature;

  @override
  String get featureId => HandoffFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    HandoffLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.handoffL10n.title;

  @override
  IconData get icon => LucideIcons.monitorSmartphone;
}
