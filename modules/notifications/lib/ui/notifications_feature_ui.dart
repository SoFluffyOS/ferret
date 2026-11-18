import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/feature/notifications_feature.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/services/services.dart';
import 'package:notifications/ui/frames/frames.dart';
import 'package:notifications/ui/pages/pages.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:protocol/notifications.dart';
import 'package:protocol/protocol.dart' as proto;
import 'package:provider/provider.dart';

/// The app side of notification mirroring: setup on the phone, notices and
/// the home card on computers.
class NotificationsFeatureUi extends FeatureUi {
  factory NotificationsFeatureUi() {
    if (!FerretNotifications.isSupported) {
      return NotificationsFeatureUi.withFeature(NotificationsFeature());
    }

    final platform = PlatformNotificationSource();
    return NotificationsFeatureUi.withFeature(
      NotificationsFeature(source: platform),
      access: platform,
    );
  }

  /// Uses [feature], and [access] for the phone's setup flow.
  NotificationsFeatureUi.withFeature(this.feature, {this.access});

  @override
  final NotificationsFeature feature;

  /// The phone's notification access switch, null on computers.
  final NotificationAccess? access;

  InboxViewModel? _inbox;
  MirrorSetupViewModel? _setup;
  AppLifecycleListener? _lifecycle;
  FeatureChanges? _mirrorChanges;
  Listenable? _uiChanges;

  @override
  String get featureId => NotificationsFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    NotificationsLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories => switch (feature.isSource) {
    true => const [],
    false => InboxViewModel.categories(platformNotificationsL10n()),
  };

  @override
  String title(BuildContext context) => context.notificationsL10n.title;

  @override
  IconData get icon => LucideIcons.bell;

  /// Access can be taken away in Android Settings, so the phone reads it
  /// again every time the user comes back.
  @override
  Future<void> onAppStarted(FeatureContext context) async {
    if (!feature.isSource) {
      _inboxFor(context);
      return;
    }

    final setup = _phoneSetup;
    if (setup == null) {
      return;
    }

    _lifecycle ??= AppLifecycleListener(
      onResume: () => unawaited(setup.refresh()),
    );
  }

  /// On the phone: where setup stands. On a computer: the inbox and what
  /// each phone says about mirroring.
  @override
  Listenable? get uiChanges {
    if (feature.isSource) {
      return _phoneSetup;
    }

    if (_uiChanges case final changes?) {
      return changes;
    }

    final mirrorChanges = FeatureChanges(feature.mirrorEvents);
    _mirrorChanges = mirrorChanges;
    final changes = Listenable.merge([?_inbox, mirrorChanges]);
    _uiChanges = changes;
    return changes;
  }

  /// On the phone, only while mirroring is on but access is off. On a
  /// computer, only once an Android phone is paired or a notification is
  /// waiting.
  @override
  bool hasHomeCard(FeatureContext feature) {
    if (this.feature.isSource) {
      final setup = _phoneSetup;
      return setup != null && setup.checked && setup.stage == .needsAccess;
    }

    return _hasPhone(feature) || !_inboxFor(feature).isEmpty;
  }

  /// On the phone, while mirroring is off.
  @override
  FeatureOffer? offerFor(BuildContext context, FeatureContext feature) {
    if (_phoneSetup?.stage != .off) {
      return null;
    }

    final phoneAccess = access;
    if (phoneAccess == null) {
      return null;
    }

    final l10n = context.notificationsL10n;
    return FeatureOffer(
      title: l10n.title,
      description: l10n.offerDescription,
      actionLabel: l10n.setUp,
      onAction: () => _openSetup(feature, phoneAccess),
    );
  }

  /// On a computer, whether a phone mirrors here: off, access missing, or
  /// not answering.
  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (this.feature.isSource || session == null) {
      return null;
    }

    final flags = session.remoteFeature(featureId)?.flags ?? const <String>[];
    if (!flags.contains(NotificationsFeature.sendFlag)) {
      return null;
    }

    final l10n = platformNotificationsL10n();
    final deviceId = device.device.id;
    if (this.feature.isUnreachable(deviceId)) {
      return FeatureHealth(.failing, reason: l10n.phoneUnreachable);
    }

    final settings = this.feature.senderSettings[deviceId];
    if (settings == null) {
      return null;
    }

    if (!settings.enabled) {
      return FeatureHealth(.off, reason: l10n.phoneMirroringOff);
    }

    if (!settings.accessGranted) {
      return FeatureHealth(.needsAttention, reason: l10n.phoneAccessOff);
    }

    return FeatureHealth(
      .ok,
      reason: l10n.phoneMirroring(settings.allowedPackages.length),
    );
  }

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      _homeCard(feature);

  /// Stops listening, for tests and hot restarts.
  void dispose() {
    _lifecycle?.dispose();
    _setup?.dispose();
    _mirrorChanges?.dispose();
    _inbox?.dispose();
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      _settings(feature);

  Widget? _homeCard(FeatureContext featureContext) {
    if (access case final phoneAccess? when feature.isSource) {
      final setup = _phoneSetup;
      if (setup == null) {
        return null;
      }

      return ChangeNotifierProvider.value(
        value: setup,
        child: PhoneHomeFrame(
          onSetUp: () => _openSetup(featureContext, phoneAccess),
        ),
      );
    }

    final inbox = _inboxFor(featureContext);

    if (!_hasPhone(featureContext) && inbox.isEmpty) {
      return null;
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: inbox),
        ChangeNotifierProvider(
          create: (_) => PhonesViewModel(
            feature: feature,
            sessionChanges: featureContext.engine.sessionChanges,
          ),
        ),
      ],
      child: const InboxCardFrame(),
    );
  }

  Widget _settings(FeatureContext featureContext) {
    if (access case final phoneAccess? when feature.isSource) {
      return ChangeNotifierProvider(
        create: (_) =>
            MirrorSetupViewModel(feature: feature, access: phoneAccess),
        child: PhoneSetupFrame(
          onChooseApps: () => _openLocalPicker(featureContext),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => PhonesViewModel(
        feature: feature,
        sessionChanges: featureContext.engine.sessionChanges,
      ),
      child: PhonesSettingsFrame(
        onChooseApps: (phone) => _openRemotePicker(featureContext, phone),
      ),
    );
  }

  /// The phone's setup state, made once so the shell can ask about it.
  MirrorSetupViewModel? get _phoneSetup {
    final phoneAccess = access;
    if (!feature.isSource || phoneAccess == null) {
      return null;
    }

    return _setup ??= MirrorSetupViewModel(
      feature: feature,
      access: phoneAccess,
    );
  }

  void _openSetup(FeatureContext featureContext, NotificationAccess access) =>
      unawaited(
        featureContext.push<void>(
          PhoneSetupPage(
            feature: feature,
            access: access,
            onChooseApps: () => _openLocalPicker(featureContext),
          ),
        ),
      );

  bool _hasPhone(FeatureContext featureContext) =>
      featureContext.engine.trustStore.devices.any(
        (device) => device.platform == proto.Platform.PLATFORM_ANDROID,
      );

  /// The computer's inbox, created once: it must listen before the first
  /// notification arrives, whichever of start-up or the home card comes first.
  InboxViewModel _inboxFor(FeatureContext featureContext) {
    if (_inbox case final inbox?) {
      return inbox;
    }

    final trustStore = featureContext.engine.trustStore;
    final inbox = InboxViewModel(
      feature: feature,
      notifier: featureContext.notifier,
      deviceName: (deviceId) => trustStore[deviceId]?.name ?? deviceId,
      strings: platformNotificationsL10n,
    );
    _inbox = inbox;
    return inbox;
  }

  void _openLocalPicker(FeatureContext featureContext) => unawaited(
    featureContext.push<void>(
      AppPickerPage(
        deviceName: platformNotificationsL10n().thisPhone,
        load: feature.localApps,
        save: (package, allowed) => feature.applySettings(
          UpdateMirrorSettings(
            apps: [AppChoice(package: package, allowed: allowed)],
          ),
        ),
      ),
    ),
  );

  void _openRemotePicker(FeatureContext featureContext, PhoneStatus phone) =>
      unawaited(
        featureContext.push<void>(
          AppPickerPage(
            deviceName: phone.name,
            load: () => feature.fetchApps(phone.deviceId),
            save: (package, allowed) => feature.updateSettings(
              phone.deviceId,
              UpdateMirrorSettings(
                apps: [AppChoice(package: package, allowed: allowed)],
              ),
            ),
          ),
        ),
      );
}
