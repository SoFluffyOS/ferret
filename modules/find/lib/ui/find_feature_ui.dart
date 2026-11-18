import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:find/feature/find_feature.dart';
import 'package:find/l10n/l10n.dart';
import 'package:find/models/models.dart';
import 'package:find/services/services.dart';
import 'package:find/ui/find_activity.dart';
import 'package:find/ui/frames/frames.dart';
import 'package:find/ui/pages/pages.dart';
import 'package:find/ui/ringing_overlay.dart';
import 'package:find/view_models/view_models.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of Find my device: "Ring" on each device, each ring as a
/// line in Activity, the ringing screen and notice with "Found it",
/// Settings, and each device's ring health.
class FindFeatureUi extends FeatureUi {
  FindFeatureUi({FindFeature? feature})
    : feature = feature ?? FindFeature(texts: _alertTexts);

  @override
  final FindFeature feature;

  late final FindViewModel viewModel = FindViewModel(feature);
  FindNotices? _notices;
  RingingOverlay? _overlay;
  AppLifecycleListener? _lifecycle;
  VoidCallback? _revealOnRing;

  /// The start of the ring the app was last brought to the front for.
  DateTime? _revealedFor;

  @override
  String get featureId => FindFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    FindLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories =>
      FindNotices.categories(platformFindL10n());

  @override
  String title(BuildContext context) => context.findL10n.title;

  @override
  IconData get icon => LucideIcons.radar;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    _notices = FindNotices(
      feature: feature,
      notifier: context.notifier,
      l10n: platformFindL10n(),
    )..start();
    _overlay = RingingOverlay(
      viewModel: viewModel,
      navigatorKey: context.navigatorKey,
    )..start();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(feature.refreshAbilities()),
    );
    void revealOnRing() => _revealWhenRinging(context);
    _revealOnRing = revealOnRing;
    viewModel.addListener(revealOnRing);
    revealOnRing();
  }

  @override
  Listenable get uiChanges => viewModel;

  /// Only while this device rings, for "Found it". Rings to other devices
  /// are lines in Activity.
  @override
  bool hasHomeCard(FeatureContext feature) => viewModel.isRingingHere;

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) =>
      findActivity(context.findL10n, viewModel);

  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    final deviceId = device.device.id;
    final health = ringHealthOf(
      supported: session.supports(featureId),
      remote: this.feature.remoteInfo(deviceId),
      lastRing: this.feature.outgoingFor(deviceId),
    );
    return _healthOf(health, device.device, platformFindL10n());
  }

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const FindCardFrame(showOutgoing: false),
      );

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final session = device.session;
    if (session == null || !session.supports(featureId)) {
      return const [];
    }

    return [
      FeatureAction(
        id: 'find.ring',
        label: context.findL10n.ring,
        icon: LucideIcons.bellRing,
        homeOrder: 30,
        onPressed: () => unawaited(_ring(feature, device)),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider(
        create: (_) => FindSettingsViewModel(this.feature),
        child: const FindSettingsFrame(),
      );

  /// Find is always on, so its part says how this device rings, and asks
  /// for attention only when Do Not Disturb access it once had is gone.
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final section = buildSettings(context, feature);
    if (section == null) {
      return const [];
    }

    return [
      FeatureSettings(
        group: .control,
        title: title(context),
        child: section,
        summary: _summaryOf(context.findL10n),
        needsAttention: this.feature.lostDndAccess,
      ),
    ];
  }

  /// Stops listening, for tests and hot restarts.
  Future<void> dispose() async {
    await _notices?.dispose();
    _overlay?.dispose();
    if (_revealOnRing case final revealOnRing?) {
      viewModel.removeListener(revealOnRing);
    }

    _lifecycle?.dispose();
    viewModel.dispose();
  }

  /// Brings Ferret to the front once per ring, so "Found it" is one click
  /// away, such as in the macOS menubar popover.
  void _revealWhenRinging(FeatureContext context) {
    final ring = viewModel.localRing;
    if (!ring.isRinging || _revealedFor == ring.startedAt) {
      return;
    }

    _revealedFor = ring.startedAt;
    unawaited(context.reveal());
  }

  /// One tap rings, and opens the ring's page so Stop and the outcome are
  /// right there.
  Future<void> _ring(FeatureContext context, DeviceStatus device) async {
    final deviceId = device.device.id;
    unawaited(viewModel.ring(deviceId));
    await context.push<void>(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: OutgoingRingPage(
          deviceId: deviceId,
          deviceName: device.device.name,
        ),
      ),
    );
  }

  /// How this device rings, in a few words, for its row in Settings.
  String _summaryOf(FindLocalizations l10n) {
    final abilities = feature.abilities;
    final ringOnSilent = feature.settings.ringOnSilent;
    if (!abilities.canPlaySound) {
      return l10n.summaryCantRing;
    }

    if (!abilities.ringsInBackground) {
      return l10n.summaryWhileOpen;
    }

    if (ringOnSilent && abilities.missingDndAccess) {
      return l10n.summaryQuietInDnd;
    }

    if (ringOnSilent && abilities.canRingWhenSilent) {
      return l10n.summaryOnSilent;
    }

    if (abilities.controlsVolume) {
      return l10n.summaryQuietOnSilent;
    }

    return l10n.summaryCurrentVolume;
  }

  FeatureHealth _healthOf(
    RingHealth health,
    TrustedDevice device,
    FindLocalizations l10n,
  ) {
    final name = device.name;
    void checkAgain() => unawaited(feature.checkAgain(device.id));

    return switch (health) {
      .unknown => FeatureHealth(.off, reason: l10n.healthChecking(name)),
      .loud => FeatureHealth(.ok, reason: l10n.healthLoud(name)),
      .followsSilent => FeatureHealth(
        .ok,
        reason: l10n.healthFollowsSilent(name),
      ),
      .needsAppOpen => FeatureHealth(
        .ok,
        reason: l10n.healthNeedsAppOpen(name),
      ),
      .needsPermission => FeatureHealth(
        .needsAttention,
        reason: l10n.healthNeedsPermission(name),
        help: l10n.healthNeedsPermissionHelp(name),
      ),
      .notAnswering => FeatureHealth(
        .failing,
        reason: l10n.healthNotAnswering(name),
        help: l10n.outgoingUnreachableDetail(name),
        onFix: checkAgain,
      ),
      .noSound => FeatureHealth(
        .failing,
        reason: l10n.healthNoSound(name),
        help: l10n.outgoingNoSoundDetail(name),
      ),
      .unsupported => FeatureHealth(
        .off,
        reason: l10n.healthUnsupported(name),
        help: l10n.healthUnsupportedHelp(name),
      ),
    };
  }

  static RingTexts _alertTexts(String requesterName) {
    final l10n = platformFindL10n();
    return RingTexts(
      title: l10n.ringingTitle,
      body: l10n.ringingBody(requesterName),
      foundIt: l10n.foundIt,
    );
  }
}
