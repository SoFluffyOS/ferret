import 'dart:async';

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

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    if (!feature.isSource) {
      _inboxFor(context);
    }
  }

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      _homeCard(feature);

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      _settings(feature);

  Widget? _homeCard(FeatureContext featureContext) {
    if (access case final phoneAccess? when feature.isSource) {
      return ChangeNotifierProvider(
        create: (_) =>
            MirrorSetupViewModel(feature: feature, access: phoneAccess),
        child: PhoneHomeFrame(
          onSetUp: () => unawaited(
            featureContext.push<void>(
              PhoneSetupPage(
                feature: feature,
                access: phoneAccess,
                onChooseApps: () => _openLocalPicker(featureContext),
              ),
            ),
          ),
        ),
      );
    }

    final inbox = _inboxFor(featureContext);

    final hasPhone = featureContext.engine.trustStore.devices.any(
      (device) => device.platform == proto.Platform.PLATFORM_ANDROID,
    );
    if (!hasPhone && inbox.isEmpty) {
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
