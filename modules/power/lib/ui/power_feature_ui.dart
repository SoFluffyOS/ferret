import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:power/feature/power_feature.dart';
import 'package:power/l10n/l10n.dart';
import 'package:power/ui/frames/frames.dart';
import 'package:power/ui/pages/power_page.dart';
import 'package:power/view_models/power_view_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// The app side of Power-ups: the Settings section with the way to the
/// ladder, and on Android a home card while a step can be taken.
class PowerFeatureUi extends FeatureUi {
  PowerFeatureUi({PowerFeature? feature, Future<bool> Function(Uri)? openLink})
    : feature = feature ?? PowerFeature(),
      _openLink = openLink ?? _openInBrowser;

  @override
  final PowerFeature feature;

  final Future<bool> Function(Uri) _openLink;
  AppLifecycleListener? _lifecycle;

  late final PowerViewModel viewModel = PowerViewModel(
    feature,
    openLink: _openLink,
  );

  @override
  String get featureId => PowerFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    PowerLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.powerL10n.title;

  @override
  IconData get icon => LucideIcons.zap;

  /// Shizuku is started and allowed in other apps, so the phone is read
  /// again every time the user comes back.
  @override
  Future<void> onAppStarted(FeatureContext context) async {
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(viewModel.refresh()),
    );
  }

  /// Power-ups are about this device alone, so there is nothing to say about
  /// another one and no chip on its card.
  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) => null;

  @override
  Listenable get uiChanges => viewModel;

  @override
  bool hasHomeCard(FeatureContext feature) => viewModel.prompt != null;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: PowerCardFrame(onOpen: () => _openPage(feature)),
      );

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: PowerSettingsFrame(onOpen: () => _openPage(feature)),
      );

  /// Stops listening for the app coming back and releases the view model.
  void dispose() {
    _lifecycle?.dispose();
    viewModel.dispose();
  }

  void _openPage(FeatureContext feature) =>
      unawaited(feature.push<void>(PowerPage(viewModel: viewModel)));

  static Future<bool> _openInBrowser(Uri link) =>
      launchUrl(link, mode: .externalApplication);
}
