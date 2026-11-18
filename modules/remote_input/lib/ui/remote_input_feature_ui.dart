import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:remote_input/feature/remote_input_feature.dart';
import 'package:remote_input/l10n/l10n.dart';

/// The app side of Remote input.
class RemoteInputFeatureUi extends FeatureUi {
  RemoteInputFeatureUi() : feature = RemoteInputFeature();

  @override
  final RemoteInputFeature feature;

  @override
  String get featureId => RemoteInputFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    RemoteInputLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.remoteInputL10n.title;

  @override
  IconData get icon => LucideIcons.mouse;
}
