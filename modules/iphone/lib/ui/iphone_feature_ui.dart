import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:iphone/feature/iphone_feature.dart';
import 'package:iphone/l10n/l10n.dart';
import 'package:iphone/models/models.dart';
import 'package:iphone/services/services.dart';
import 'package:iphone/ui/frames/frames.dart';
import 'package:iphone/ui/pages/pages.dart';
import 'package:iphone/view_models/view_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of the iPhone link on Windows, Linux and macOS: the "Now
/// playing on iPhone" card, the iPhone's notifications as notices with their
/// actions, and pairing in Settings. Shows nothing on phones.
class IphoneFeatureUi extends FeatureUi {
  IphoneFeatureUi({IphoneFeature? feature})
    : feature = feature ?? IphoneFeature();

  @override
  final IphoneFeature feature;

  late final IphoneViewModel viewModel = IphoneViewModel(feature);
  IphoneNotices? _notices;
  AppLifecycleListener? _lifecycle;

  @override
  String get featureId => IphoneFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    IphoneLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories {
    if (!feature.isSupported) {
      return const [];
    }

    return IphoneNotices.categories(platformIphoneL10n());
  }

  @override
  String title(BuildContext context) => context.iphoneL10n.title;

  @override
  IconData get icon => LucideIcons.smartphone;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    if (!feature.isSupported) {
      return;
    }

    _notices = IphoneNotices(
      feature: feature,
      notifier: context.notifier,
      l10n: platformIphoneL10n(),
    )..start();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(feature.refresh()),
    );
  }

  @override
  Listenable get uiChanges => viewModel;

  /// Only while the iPhone plays something, or the link needs the person.
  @override
  bool hasHomeCard(FeatureContext feature) => viewModel.hasCard;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: IphoneCardFrame(onSetUp: () => unawaited(_openSetup(feature))),
      );

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    if (!this.feature.isSupported) {
      return null;
    }

    return ChangeNotifierProvider(
      create: (_) => IphoneSettingsViewModel(this.feature),
      child: const IphoneSettingsFrame(),
    );
  }

  /// Under "Other apps" on a computer; nowhere on a phone, which can't be
  /// an iPhone's Bluetooth client.
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final child = buildSettings(context, feature);
    if (child == null) {
      return const [];
    }

    final l10n = context.iphoneL10n;
    final enabled = this.feature.settings.enabled;
    final link = this.feature.link;

    return [
      FeatureSettings(
        group: .otherApps,
        title: l10n.title,
        child: child,
        summary: switch (enabled) {
          true => _summary(l10n, link),
          false => '',
        },
        isOn: enabled,
        needsAttention: enabled && _isFailing(link),
      ),
    ];
  }

  @override
  SettingsGroup get settingsGroup => .otherApps;

  /// Stops listening, for tests and hot restarts.
  void dispose() {
    _notices?.dispose();
    _lifecycle?.dispose();
    viewModel.dispose();
  }

  String _summary(IphoneLocalizations l10n, LinkState link) {
    final device = switch (link.deviceName.isEmpty) {
      true => l10n.yourIphone,
      false => link.deviceName,
    };

    return switch (link.phase) {
      .off => '',
      .unsupported || .notConfigured => l10n.summaryUnavailable,
      .bluetoothOff => l10n.problemBluetoothOffTitle,
      .unauthorized => l10n.problemUnauthorizedTitle,
      .noDevice => l10n.problemNoDeviceTitle,
      .connecting => l10n.statusConnecting(device),
      .connected => l10n.statusConnected(device),
      .outOfReach || .failed => l10n.summaryOutOfReach(device),
      .notShared => l10n.summaryNotShared(device),
    };
  }

  /// What was working and stopped: Bluetooth went off or was refused, or
  /// the iPhone stopped sharing. Not an iPhone that is away, and not a
  /// setup that was never finished.
  bool _isFailing(LinkState link) => switch (link.phase) {
    .bluetoothOff || .unauthorized || .notShared => true,
    _ => false,
  };

  Future<void> _openSetup(FeatureContext context) => context.push<void>(
    ChangeNotifierProvider(
      create: (_) => IphoneSettingsViewModel(feature),
      child: const IphoneSetupPage(),
    ),
  );
}
