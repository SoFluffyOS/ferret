import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_wake/ferret_wake.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:wake/l10n/l10n.dart';
import 'package:wake/models/models.dart';
import 'package:wake/ui/frames/frames.dart';
import 'package:wake/ui/pages/pages.dart';
import 'package:wake/view_models/view_models.dart';

/// The app side of Wake-on-LAN: "Wake" on an offline computer's row and
/// page, "Waking…" until it connects or "Didn't wake" with the way to turn
/// it on, how likely each computer is to wake, and a computer's own
/// Settings.
class WakeFeatureUi extends FeatureUi {
  WakeFeatureUi({WakeFeature? feature})
    : feature = feature ?? WakeFeature(isComputer: _isComputer);

  @override
  final WakeFeature feature;

  late final WakeViewModel viewModel = WakeViewModel(feature);
  AppLifecycleListener? _lifecycle;

  static const wakeActionId = 'wake.wake';
  static const helpActionId = 'wake.help';

  static bool get _isComputer => switch (defaultTargetPlatform) {
    .macOS || .windows || .linux => true,
    _ => false,
  };

  @override
  String get featureId => WakeFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    WakeLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.wakeL10n.title;

  @override
  IconData get icon => LucideIcons.power;

  @override
  Listenable get uiChanges => viewModel;

  @override
  bool hasHomeCard(FeatureContext feature) => false;

  /// A computer reads its cards again when Ferret comes back to the front,
  /// so a setting just turned on in the system shows, and reaches paired
  /// devices.
  @override
  Future<void> onAppStarted(FeatureContext context) async {
    if (!feature.isComputer) {
      return;
    }

    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(viewModel.refresh()),
    );
  }

  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    if (!device.isConnected || !this.feature.canWake(device.device)) {
      return null;
    }

    final l10n = lookupWakeLocalizations(
      AppLocale.pick(WakeLocalizations.supportedLocales),
    );
    final name = device.device.name;
    return switch (WakeReadiness.of(device.device.wake)) {
      .ready => FeatureHealth(.ok, reason: l10n.healthReady),
      .wiredUnknown => FeatureHealth(.ok, reason: l10n.healthWiredUnknown),
      .wiredOff => FeatureHealth(
        .off,
        reason: l10n.healthWiredOff(name),
        help: l10n.healthHelp(name),
      ),
      .wifiOnly => FeatureHealth(
        .off,
        reason: l10n.healthWifiOnly,
        help: l10n.helpBest,
      ),
      .unknown => null,
    };
  }

  @override
  List<FeatureAction> offlineActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    if (device.isConnected || device.isReconnecting) {
      return const [];
    }

    if (!this.feature.canWake(device.device)) {
      return const [];
    }

    final l10n = context.wakeL10n;
    final deviceId = device.device.id;
    void wake() => unawaited(viewModel.wake(deviceId));
    final help = FeatureAction(
      id: helpActionId,
      label: l10n.howToTurnOn,
      icon: LucideIcons.circleQuestionMark,
      onPressed: () => unawaited(_openHelp(feature, device.device)),
    );

    return switch (viewModel.attemptFor(deviceId)?.phase) {
      null => [
        FeatureAction(
          id: wakeActionId,
          label: l10n.wake,
          icon: LucideIcons.power,
          onPressed: wake,
        ),
      ],
      .waking => [
        FeatureAction(
          id: wakeActionId,
          label: l10n.wake,
          icon: LucideIcons.power,
          onPressed: null,
        ),
      ],
      .didntWake || .couldntSend => [
        FeatureAction(
          id: wakeActionId,
          label: l10n.tryAgain,
          icon: LucideIcons.power,
          onPressed: wake,
        ),
        help,
      ],
    };
  }

  @override
  String? offlineStatus(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    if (device.isConnected) {
      return null;
    }

    final l10n = context.wakeL10n;
    return switch (viewModel.attemptFor(device.device.id)?.phase) {
      .waking => l10n.waking(device.device.name),
      .didntWake => l10n.didntWake,
      .couldntSend => l10n.couldntSend,
      null => null,
    };
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    if (!this.feature.isComputer) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: WakeSettingsFrame(onHelp: () => unawaited(_openOwnHelp(feature))),
    );
  }

  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final section = buildSettings(context, feature);
    if (section == null) {
      return const [];
    }

    final l10n = context.wakeL10n;
    final readiness = WakeReadiness.of(NetworkCard.shareable(viewModel.cards));
    final isOn = viewModel.shares && readiness == .ready;
    return [
      FeatureSettings(
        group: .control,
        title: title(context),
        child: section,
        summary: switch (readiness) {
          _ when !viewModel.shares => l10n.settingsNotReady,
          .ready => l10n.settingsReady,
          .wifiOnly => l10n.settingsWifiOnly,
          .wiredOff => l10n.settingsNotReady,
          .wiredUnknown || .unknown => '',
        },
        isOn: isOn,
      ),
    ];
  }

  Future<void> _openHelp(FeatureContext context, TrustedDevice device) =>
      context.push<void>(
        WakeHelpPage(
          platform: device.platform,
          deviceName: device.name,
          told: device.wake?.interfaces,
          fromIphone: defaultTargetPlatform == .iOS,
        ),
      );

  Future<void> _openOwnHelp(FeatureContext context) => context.push<void>(
    WakeHelpPage(
      platform: context.engine.device.platform,
      told: [for (final card in viewModel.cards) card.toInterface()],
    ),
  );

  /// Stops listening for the app coming back and releases the view model.
  void dispose() {
    _lifecycle?.dispose();
    viewModel.dispose();
  }
}
