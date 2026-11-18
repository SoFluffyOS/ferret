import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/feature/messages_feature.dart';
import 'package:messages/l10n/l10n.dart';

/// The app side of Messages.
class MessagesFeatureUi extends FeatureUi {
  MessagesFeatureUi() : feature = MessagesFeature();

  @override
  final MessagesFeature feature;

  @override
  String get featureId => MessagesFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    MessagesLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.messagesL10n.title;

  @override
  IconData get icon => LucideIcons.messageSquare;
}
