import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_notifications/ferret_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/feature/notifications_feature.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/models/models.dart';
import 'package:notifications/services/services.dart';
import 'package:notifications/ui/frames/frames.dart';
import 'package:notifications/ui/notifications_activity.dart';
import 'package:notifications/ui/pages/pages.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:protocol/notifications.dart';
import 'package:protocol/protocol.dart' as proto;
import 'package:provider/provider.dart';

/// The app side of notification mirroring: setup on the phone, notices and
/// lines in Activity on computers.
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

  /// The id of the section a phone's notifications show in.
  static const sectionId = 'notifications';

  @override
  final NotificationsFeature feature;

  /// The phone's notification access switch, null on computers.
  final NotificationAccess? access;

  InboxViewModel? _inbox;
  MirrorSetupViewModel? _setup;
  AppLifecycleListener? _lifecycle;
  FeatureChanges? _mirrorChanges;
  FeatureChanges? _deviceChanges;
  Listenable? _uiChanges;
  final StreamController<void> _devicesChanged = .broadcast();
  StreamSubscription<Object?>? _devicesSubscription;

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
    final deviceChanges = FeatureChanges(_devicesChanged.stream);
    _mirrorChanges = mirrorChanges;
    _deviceChanges = deviceChanges;
    final changes = Listenable.merge([?_inbox, mirrorChanges, deviceChanges]);
    _uiChanges = changes;
    return changes;
  }

  /// On the phone, only while mirroring is on but access is off. Never on a
  /// computer: what its phones sent is in [activity].
  @override
  bool hasHomeCard(FeatureContext feature) {
    if (!this.feature.isSource) {
      return false;
    }

    final setup = _phoneSetup;
    return setup != null && setup.checked && setup.stage == .needsAccess;
  }

  /// On a computer, one line per phone with notifications waiting. Tapping
  /// it opens the full list.
  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    if (this.feature.isSource) {
      return const [];
    }

    final inbox = _inboxFor(feature);

    return NotificationsActivity.items(
      context.notificationsL10n,
      inbox.byDevice,
      deviceName: inbox.deviceName,
      onOpen: () => _openInbox(feature),
    );
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
      description: l10n.offerDescription(ThisComputer.handheld),
      actionLabel: l10n.setUp,
      onAction: () => _openSetup(feature, phoneAccess),
    );
  }

  /// On a computer, whether a phone mirrors here: off, access missing, or
  /// not answering. On the phone, whether it sends to that computer.
  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    final flags = session.remoteFeature(featureId)?.flags ?? const <String>[];
    if (this.feature.isSource) {
      return _phoneHealth(flags);
    }

    if (!flags.contains(NotificationsFeature.sendFlag)) {
      return null;
    }

    final l10n = platformNotificationsL10n();
    final deviceId = device.device.id;
    final name = device.device.name;
    if (!this.feature.receiverPreferences.showsFrom(deviceId)) {
      return FeatureHealth(
        .off,
        reason: l10n.healthHiddenHere,
        help: l10n.healthHiddenHelp,
      );
    }

    if (this.feature.isUnreachable(deviceId)) {
      return FeatureHealth(
        .failing,
        reason: l10n.phoneUnreachable(name),
        onFix: () => unawaited(this.feature.fetchSettings(deviceId)),
      );
    }

    final settings = this.feature.senderSettings[deviceId];
    if (settings == null) {
      return FeatureHealth(.off, reason: l10n.phoneChecking);
    }

    if (!settings.enabled) {
      return FeatureHealth(
        .off,
        reason: l10n.phoneMirroringOff(name),
        help: l10n.howBody(name),
      );
    }

    if (!settings.accessGranted) {
      return FeatureHealth(
        .needsAttention,
        reason: l10n.phoneAccessOff,
        help: l10n.healthAccessHelp(name),
      );
    }

    return FeatureHealth(
      .ok,
      reason: l10n.appsSummary(
        settings.effectiveFilter,
        settings.namedAppCount,
      ),
    );
  }

  /// On a computer, for a phone that mirrors here: its app picker, on the
  /// phone's page only.
  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final deviceId = device.device.id;
    final settings = this.feature.senderSettings[deviceId];
    if (this.feature.isSource ||
        settings == null ||
        !settings.enabled ||
        !this.feature.receiverPreferences.showsFrom(deviceId)) {
      return const [];
    }

    return [
      FeatureAction(
        id: 'notifications.choose_apps',
        label: context.notificationsL10n.actionChooseAppsShort,
        tooltip: context.notificationsL10n.actionChooseApps,
        icon: LucideIcons.bell,
        onPressed: () =>
            _openRemotePicker(feature, deviceId, device.device.name),
      ),
    ];
  }

  /// The phones that offered their notifications since Ferret started, so
  /// the section stays while one of them is offline.
  final Set<String> _offeredBy = {};

  /// On a computer, what a phone's apps said: for a phone that offers its
  /// notifications or did before it went offline, and for one that still
  /// has some waiting here.
  @override
  List<FeatureSection> deviceSections(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    if (this.feature.isSource) {
      return const [];
    }

    final flags =
        device.session?.remoteFeature(featureId)?.flags ?? const <String>[];
    final inbox = _inboxFor(feature);
    final deviceId = device.device.id;
    final waiting = inbox.byDevice[deviceId]?.length ?? 0;
    if (flags.contains(NotificationsFeature.sendFlag)) {
      _offeredBy.add(deviceId);
    }

    if (!_offeredBy.contains(deviceId) && waiting == 0) {
      return const [];
    }

    final isOffOnPhone =
        !(this.feature.senderSettings[deviceId]?.enabled ?? true);
    final isHiddenHere = !this.feature.receiverPreferences.showsFrom(deviceId);

    return [
      FeatureSection(
        id: sectionId,
        title: title(context),
        icon: icon,
        order: 30,
        badge: waiting,
        isSetUp: !isOffOnPhone && !isHiddenHere,
        builder: (_) =>
            InboxPage(inbox: inbox, phones: () => _phonesViewModel(feature)),
      ),
    ];
  }

  /// On a computer, for a phone that offers its notifications: whether they
  /// show here, and whether the phone holds them back while it is in use.
  @override
  List<DevicePermission> devicePermissions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final flags =
        device.session?.remoteFeature(featureId)?.flags ?? const <String>[];
    if (this.feature.isSource ||
        !flags.contains(NotificationsFeature.sendFlag)) {
      return const [];
    }

    final l10n = context.notificationsL10n;
    final deviceId = device.device.id;
    final shows = this.feature.receiverPreferences.showsFrom(deviceId);
    final settings = this.feature.senderSettings[deviceId];

    return [
      DevicePermission(
        label: l10n.permissionShow,
        value: shows,
        inUse: shows && (settings?.enabled ?? false),
        onChanged: (value) => unawaited(_setShowsFrom(deviceId, value)),
      ),
      if (settings != null && settings.enabled && shows)
        DevicePermission(
          label: l10n.permissionHold,
          detail: l10n.skipWhileUsingDetail,
          value: settings.skipWhileUsing,
          onChanged: (value) => unawaited(_setSkipWhileUsing(deviceId, value)),
        ),
    ];
  }

  /// On the phone and on a computer with an Android phone paired, under
  /// "To your computer" and "From your phone".
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final child = _settings(feature);
    if (child == null) {
      return const [];
    }

    final l10n = context.notificationsL10n;
    final state = switch (this.feature.isSource) {
      true => _phoneSettingsState(l10n),
      false => _computerSettingsState(l10n, feature),
    };

    return [
      FeatureSettings(
        group: .phone,
        title: l10n.title,
        child: child,
        summary: state.summary,
        isOn: state.isOn,
        needsAttention: state.needsAttention,
      ),
    ];
  }

  @override
  SettingsGroup get settingsGroup => .phone;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      _homeCard(feature);

  /// Stops listening, for tests and hot restarts.
  void dispose() {
    _lifecycle?.dispose();
    _setup?.dispose();
    unawaited(_devicesSubscription?.cancel());
    _deviceChanges?.dispose();
    unawaited(_devicesChanged.close());
    _mirrorChanges?.dispose();
    _inbox?.dispose();
  }

  /// On a computer, only once an Android phone is paired: before that the
  /// section has nothing to set.
  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      _settings(feature);

  /// How this phone's mirroring is doing, for a computer that shows it.
  FeatureHealth? _phoneHealth(List<String> flags) {
    final setup = _phoneSetup;
    if (setup == null || !flags.contains(NotificationsFeature.receiveFlag)) {
      return null;
    }

    final l10n = platformNotificationsL10n();
    if (!setup.checked) {
      return FeatureHealth(.off, reason: l10n.phoneChecking);
    }

    return switch (setup.stage) {
      .off => FeatureHealth(
        .off,
        reason: l10n.healthOffThisPhone(ThisComputer.handheld),
        help: l10n.healthOffThisPhoneHelp(ThisComputer.handheld),
      ),
      .needsAccess => FeatureHealth(
        .needsAttention,
        reason: l10n.phoneAccessOff,
        onFix: () => unawaited(setup.openAccessSettings()),
      ),
      .ready => FeatureHealth(
        .ok,
        reason: l10n.appsSummary(setup.appFilter, setup.namedAppCount),
      ),
    };
  }

  _SettingsState _phoneSettingsState(NotificationsLocalizations l10n) {
    final setup = _phoneSetup;
    if (setup == null) {
      return const (summary: '', isOn: false, needsAttention: false);
    }

    return switch (setup.stage) {
      .off => const (summary: '', isOn: false, needsAttention: false),
      .needsAccess => (
        summary: l10n.settingsNeedsAccess,
        isOn: true,
        needsAttention: setup.checked,
      ),
      .ready => (
        summary: l10n.appsSummary(setup.appFilter, setup.namedAppCount),
        isOn: true,
        needsAttention: false,
      ),
    };
  }

  /// The phone that needs the person comes first, then one that mirrors,
  /// then one that did the last time it was here.
  _SettingsState _computerSettingsState(
    NotificationsLocalizations l10n,
    FeatureContext featureContext,
  ) {
    final preferences = feature.receiverPreferences;
    final phones = [
      for (final phone in _pairedPhones(featureContext))
        if (preferences.showsFrom(phone.deviceId)) phone,
    ];

    for (final phone in phones) {
      final settings = feature.senderSettings[phone.deviceId];
      if (settings != null && settings.enabled && !settings.accessGranted) {
        return (
          summary: l10n.settingsNeedsAccessOn(phone.name),
          isOn: true,
          needsAttention: true,
        );
      }

      if (feature.isUnreachable(phone.deviceId) &&
          preferences.wasMirroring(phone.deviceId)) {
        return (
          summary: l10n.phoneUnreachable(phone.name),
          isOn: true,
          needsAttention: true,
        );
      }
    }

    for (final phone in phones) {
      final settings = feature.senderSettings[phone.deviceId];
      if (settings != null && settings.enabled) {
        return (
          summary: l10n.appsSummary(
            settings.effectiveFilter,
            settings.namedAppCount,
          ),
          isOn: true,
          needsAttention: false,
        );
      }
    }

    return (
      summary: '',
      isOn: phones.any((phone) => preferences.wasMirroring(phone.deviceId)),
      needsAttention: false,
    );
  }

  Future<void> _setShowsFrom(String deviceId, bool value) async {
    await feature.receiverPreferences.setShowsFrom(deviceId, value);
    _devicesChanged.add(null);
  }

  /// The phone keeps the setting; when it can't be reached, ask again so
  /// the switch shows what the phone really has.
  Future<void> _setSkipWhileUsing(String deviceId, bool value) async {
    try {
      await feature.updateSettings(
        deviceId,
        UpdateMirrorSettings(skipWhileUsing: value),
      );
    } on Object {
      await feature.fetchSettings(deviceId);
    }
  }

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

    return null;
  }

  /// Opens the list under the first phone that has something waiting.
  void _openInbox(FeatureContext featureContext) {
    final waiting = _inboxFor(featureContext).byDevice.entries.where(
      (entry) => entry.value.isNotEmpty,
    );
    final deviceId = waiting.firstOrNull?.key;
    if (deviceId == null) {
      return;
    }

    unawaited(featureContext.openSection(deviceId, sectionId));
  }

  Widget? _settings(FeatureContext featureContext) {
    if (access case final phoneAccess? when feature.isSource) {
      return ChangeNotifierProvider(
        create: (_) =>
            MirrorSetupViewModel(feature: feature, access: phoneAccess),
        child: PhoneSetupFrame(
          onChooseApps: () => _openLocalPicker(featureContext),
        ),
      );
    }

    if (!_hasPhone(featureContext)) {
      return null;
    }

    return ChangeNotifierProvider(
      create: (_) => _phonesViewModel(featureContext),
      child: const PhonesSettingsFrame(),
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
      _pairedPhones(featureContext).isNotEmpty;

  List<PairedPhone> _pairedPhones(FeatureContext featureContext) => [
    for (final device in featureContext.engine.trustStore.devices)
      if (device.platform == proto.Platform.PLATFORM_ANDROID)
        (deviceId: device.id, name: device.name),
  ];

  PhonesViewModel _phonesViewModel(FeatureContext featureContext) =>
      PhonesViewModel(
        feature: feature,
        sessionChanges: featureContext.engine.sessionChanges,
        pairedPhones: () => _pairedPhones(featureContext),
        pairingChanges: featureContext.engine.trustStore.changes,
      );

  /// The computer's inbox, created once: it must listen before the first
  /// notification arrives, whichever of start-up or the home card comes first.
  InboxViewModel _inboxFor(FeatureContext featureContext) {
    if (_inbox case final inbox?) {
      return inbox;
    }

    final engine = featureContext.engine;
    final trustStore = engine.trustStore;
    _devicesSubscription = engine.deviceChanges.listen((_) {
      _devicesChanged.add(null);
      final paired = {for (final device in trustStore.devices) device.id};
      unawaited(_inbox?.keepOnly(paired));
    });

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
        deviceName: platformNotificationsL10n().thisPhone(
          ThisComputer.handheld,
        ),
        load: () async => (
          settings: await feature.localSettings(),
          apps: await feature.localApps(),
        ),
        update: feature.applySettings,
      ),
    ),
  );

  void _openRemotePicker(
    FeatureContext featureContext,
    String deviceId,
    String deviceName,
  ) => unawaited(
    featureContext.push<void>(
      AppPickerPage(
        deviceName: deviceName,
        load: () => _remoteApps(deviceId),
        update: (update) => feature.updateSettings(deviceId, update),
      ),
    ),
  );

  Future<AppList> _remoteApps(String deviceId) async {
    final settings = await feature.fetchSettings(deviceId);
    if (settings == null) {
      throw const SessionClosedException();
    }

    return (settings: settings, apps: await feature.fetchApps(deviceId));
  }
}

/// What the Settings row says about notifications.
typedef _SettingsState = ({String summary, bool isOn, bool needsAttention});
