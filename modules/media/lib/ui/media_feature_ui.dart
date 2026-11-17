import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:media/feature/media_feature.dart';
import 'package:media/l10n/l10n.dart';

/// The app side of Media.
class MediaFeatureUi extends FeatureUi {
  MediaFeatureUi() : feature = MediaFeature();

  @override
  final MediaFeature feature;

  @override
  String get featureId => MediaFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    MediaLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.mediaL10n.title;

  @override
  IconData get icon => LucideIcons.music;
}
