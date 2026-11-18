import 'package:calls/feature/calls_feature.dart';
import 'package:calls/l10n/l10n.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The app side of Calls.
class CallsFeatureUi extends FeatureUi {
  CallsFeatureUi() : feature = CallsFeature();

  @override
  final CallsFeature feature;

  @override
  String get featureId => CallsFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    CallsLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.callsL10n.title;

  @override
  IconData get icon => LucideIcons.phone;
}
