import 'package:clipboard/feature/clipboard_feature.dart';
import 'package:clipboard/l10n/l10n.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The app side of Clipboard.
class ClipboardFeatureUi extends FeatureUi {
  ClipboardFeatureUi() : feature = ClipboardFeature();

  @override
  final ClipboardFeature feature;

  @override
  String get featureId => ClipboardFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    ClipboardLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.clipboardL10n.title;

  @override
  IconData get icon => LucideIcons.clipboard;
}
