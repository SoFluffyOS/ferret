import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_messages/ferret_messages.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/feature/messages_feature.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/services/services.dart';
import 'package:messages/ui/frames/frames.dart';
import 'package:messages/ui/messages_activity.dart';
import 'package:messages/ui/pages/pages.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:protocol/protocol.dart' as proto;
import 'package:provider/provider.dart';

/// The app side of Messages: setup on the phone; on computers the Messages
/// page, unread texts in Activity, notices with Reply, and Settings.
class MessagesFeatureUi extends FeatureUi {
  factory MessagesFeatureUi() {
    if (FerretMessages.isSupported) {
      return MessagesFeatureUi.withFeature(
        MessagesFeature(source: PlatformSmsSource()),
      );
    }

    return MessagesFeatureUi.withFeature(
      MessagesFeature(
        cacheStore: FileCacheStore(() async {
          final paths = await AppPaths.get();
          final folder = await paths.create(
            paths.feature(MessagesFeature.featureId),
          );
          return folder.path;
        }),
      ),
    );
  }

  MessagesFeatureUi.withFeature(this.feature);

  /// The id of the section a phone's texts show in.
  static const sectionId = 'messages';

  @override
  final MessagesFeature feature;

  IncomingNotices? _notices;
  StreamSubscription<List<TrustedDevice>>? _trustChanges;
  CardViewModel? _card;
  FeatureChanges? _changes;
  Listenable? _uiChanges;

  /// The conversation the Messages section opens on, by phone, and a tick
  /// per request so asking for another one opens it in a section that is
  /// already showing.
  final Map<String, int> _wantedThreads = {};
  final ValueNotifier<int> _threadRequests = ValueNotifier(0);

  @override
  String get featureId => MessagesFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    MessagesLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories => switch (feature.isSource) {
    true => const [],
    false => IncomingNotices.categories(platformMessagesL10n()),
  };

  @override
  String title(BuildContext context) => context.messagesL10n.title;

  @override
  IconData get icon => LucideIcons.messageSquare;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    if (feature.isSource || _notices != null) {
      return;
    }

    await initializeDateFormatting();

    final library = feature.library;
    final trust = context.engine.trustStore;
    await library.forgetUnpaired(trust);
    _trustChanges = trust.changes.listen(
      (_) => unawaited(library.forgetUnpaired(trust)),
    );
    final notices = IncomingNotices(
      library: library,
      notifier: context.notifier,
      enabled: () => feature.settings.notify,
      isShowing: (deviceId, threadId) =>
          library.isVisible(deviceId, threadId) &&
          WidgetsBinding.instance.lifecycleState == .resumed,
      strings: platformMessagesL10n,
      deviceName: (deviceId) => _nameOf(context, deviceId),
      onOpen: (deviceId, threadId) =>
          unawaited(_openFromNotice(context, deviceId, threadId)),
    )..start();
    _notices = notices;
  }

  @override
  Listenable get uiChanges => _uiChanges ??= Listenable.merge([
    _changes ??= FeatureChanges(switch (feature.sourceService) {
      final SourceService service => service.changes,
      null => feature.library.events,
    }),
    _threadRequests,
  ]);

  /// Only on the phone, while Messages are on but SMS access is missing. A
  /// computer shows unread texts in [activity] and opens them from the
  /// phone's row.
  @override
  bool hasHomeCard(FeatureContext feature) {
    final service = this.feature.sourceService;
    if (service == null) {
      return false;
    }

    final access = service.access;
    return access.hasTelephony && service.settings.enabled && !access.canRead;
  }

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    if (this.feature.sourceService != null) {
      return const [];
    }

    final trustStore = feature.engine.trustStore;
    return messagesActivity(
      l10n: context.messagesL10n,
      library: this.feature.library,
      deviceName: (deviceId) => _nameOf(feature, deviceId),
      isPaired: (deviceId) => trustStore[deviceId] != null,
      onOpen: (deviceId, threadId) =>
          _openMessages(feature, deviceId, threadId: threadId),
    );
  }

  /// On a phone that can text, while Messages are off.
  @override
  FeatureOffer? offerFor(BuildContext context, FeatureContext feature) {
    final service = this.feature.sourceService;
    if (service == null ||
        !service.access.hasTelephony ||
        service.settings.enabled) {
      return null;
    }

    final l10n = context.messagesL10n;
    return FeatureOffer(
      title: l10n.title,
      description: l10n.offerDescription,
      actionLabel: l10n.setUp,
      onAction: () => _openSetup(feature, service),
    );
  }

  /// On a computer, how a phone's texts are doing here. On a phone that
  /// can text, whether a computer may read them.
  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    if (this.feature.sourceService case final service?) {
      return _phoneHealth(feature, service, session);
    }

    if (!MessagesFeature.isPhone(session)) {
      return null;
    }

    final strings = platformMessagesL10n();
    final name = device.device.name;
    final deviceId = device.device.id;
    return switch (this.feature.library.phone(deviceId).readiness) {
      .ready => FeatureHealth(.ok, reason: strings.healthOk),
      .unreachable => FeatureHealth(
        .failing,
        reason: strings.healthUnreachable(name),
        onFix: () => unawaited(this.feature.library.refresh(deviceId)),
      ),
      .off => FeatureHealth(
        .off,
        reason: strings.healthOff(name),
        help: strings.healthOffHelp(name),
      ),
      .noAccess => FeatureHealth(
        .needsAttention,
        reason: strings.healthNoAccess,
        help: strings.healthNoAccessHelp(name),
      ),
      .checking || .offline => FeatureHealth(
        .off,
        reason: strings.healthChecking,
      ),
    };
  }

  /// On a phone that can text, and on a computer once an Android phone is
  /// paired or texts are saved, under "To your computer" and "From your
  /// phone".
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final l10n = context.messagesL10n;
    final state = switch (this.feature.sourceService) {
      final SourceService service => _phoneSettingsState(l10n, service),
      null => _computerSettingsState(l10n, feature),
    };
    final child = buildSettings(context, feature);
    if (state == null || child == null) {
      return const [];
    }

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
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) {
    if (this.feature.sourceService case final service?) {
      return ChangeNotifierProvider(
        create: (_) => PhoneSetupViewModel(service),
        child: PhoneCardFrame(onSetUp: () => _openSetup(feature, service)),
      );
    }

    return ChangeNotifierProvider.value(
      value: _cardFor(feature),
      child: MessagesCardFrame(
        onOpen: (deviceId) => _openMessages(feature, deviceId),
      ),
    );
  }

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    if (this.feature.isSource) {
      return const [];
    }

    final deviceId = device.device.id;
    final isPhone = switch (device.session) {
      final Session session => MessagesFeature.isPhone(session),
      null => false,
    };
    if (!isPhone && !this.feature.library.hasHistory(deviceId)) {
      return const [];
    }

    return [
      FeatureAction(
        id: 'messages.open',
        label: context.messagesL10n.title,
        icon: LucideIcons.messageSquare,
        onPressed: () => _openMessages(feature, deviceId),
        sectionId: sectionId,
      ),
    ];
  }

  /// On a computer, a phone's texts: for a phone that is connected, and
  /// for one whose texts are saved here.
  @override
  List<FeatureSection> deviceSections(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    if (this.feature.isSource) {
      return const [];
    }

    final deviceId = device.device.id;
    final isPhone = switch (device.session) {
      final Session session => MessagesFeature.isPhone(session),
      null => false,
    };
    final library = this.feature.library;
    if (!isPhone && !library.hasHistory(deviceId)) {
      return const [];
    }

    return [
      FeatureSection(
        id: sectionId,
        title: context.messagesL10n.title,
        icon: icon,
        order: 10,
        badge: library.unreadTotal(deviceId),
        fillsPane: true,
        isSetUp: library.phone(deviceId).readiness != .off,
        builder: (_) => MessagesPage(
          key: ValueKey((deviceId, _threadRequests.value)),
          library: library,
          deviceId: deviceId,
          phoneName: device.device.name,
          initialThreadId: _wantedThreads.remove(deviceId),
          onThreadOpened: (openedThreadId) =>
              unawaited(_notices?.clear(deviceId, openedThreadId)),
        ),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    if (this.feature.sourceService case final service?) {
      return ChangeNotifierProvider(
        create: (_) => PhoneSetupViewModel(service),
        child: const PhoneSetupFrame(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ComputerSettingsViewModel(
        settings: this.feature.settings,
        library: this.feature.library,
      ),
      child: const ComputerSettingsFrame(),
    );
  }

  FeatureHealth? _phoneHealth(
    FeatureContext context,
    SourceService service,
    Session session,
  ) {
    final reads =
        session
            .remoteFeature(featureId)
            ?.flags
            .contains(MessagesFeature.receiveFlag) ??
        false;
    final access = service.access;
    if (!reads || !access.hasTelephony) {
      return null;
    }

    final strings = platformMessagesL10n();
    if (!service.settings.enabled) {
      return FeatureHealth(
        .off,
        reason: strings.healthOffThisPhone,
        help: strings.healthOffThisPhoneHelp,
      );
    }

    if (!access.canRead) {
      return FeatureHealth(
        .needsAttention,
        reason: strings.healthNoAccess,
        onFix: () => _openSetup(context, service),
      );
    }

    return FeatureHealth(.ok, reason: strings.healthOk);
  }

  /// Null on a device that can't text: there is nothing to set.
  _SettingsState? _phoneSettingsState(
    MessagesLocalizations l10n,
    SourceService service,
  ) {
    final access = service.access;
    if (!access.hasTelephony) {
      return null;
    }

    if (!service.settings.enabled) {
      return (summary: '', isOn: false, needsAttention: false);
    }

    if (!access.canRead) {
      return (
        summary: l10n.settingsNeedsAccess,
        isOn: true,
        needsAttention: true,
      );
    }

    return (summary: '', isOn: true, needsAttention: false);
  }

  /// Null until an Android phone is paired or texts are saved. The phone
  /// that needs the person speaks first.
  _SettingsState? _computerSettingsState(
    MessagesLocalizations l10n,
    FeatureContext context,
  ) {
    final library = feature.library;
    final phones = [
      for (final device in context.engine.trustStore.devices)
        if (device.platform == proto.Platform.PLATFORM_ANDROID) device,
    ];
    final hasSaved = library.deviceIds.any(library.hasHistory);
    if (phones.isEmpty && !hasSaved) {
      return null;
    }

    for (final device in phones) {
      final phone = library.phone(device.id);
      final wasOn = phone.status?.enabled ?? library.hasHistory(device.id);
      if (phone.readiness == .noAccess) {
        return (
          summary: l10n.settingsNeedsAccessOn(device.name),
          isOn: true,
          needsAttention: true,
        );
      }

      if (phone.readiness == .unreachable && wasOn) {
        return (
          summary: l10n.healthUnreachable(device.name),
          isOn: true,
          needsAttention: true,
        );
      }
    }

    final isOn = phones.any(
      (device) => switch (library.phone(device.id).readiness) {
        .ready => true,
        .off => false,
        _ => library.hasHistory(device.id),
      },
    );
    return (summary: '', isOn: isOn, needsAttention: false);
  }

  /// Stops showing notices.
  Future<void> dispose() async {
    await _trustChanges?.cancel();
    await _notices?.stop();
    _notices = null;
    _card?.dispose();
    _changes?.dispose();
    _threadRequests.dispose();
  }

  /// The computer's home card, made once so the shell can ask whether it
  /// has anything to show.
  CardViewModel _cardFor(FeatureContext context) {
    if (_card case final card?) {
      return card;
    }

    final trustStore = context.engine.trustStore;
    final card = CardViewModel(
      library: feature.library,
      deviceName: (deviceId) => _nameOf(context, deviceId),
      isPaired: (deviceId) => trustStore[deviceId] != null,
    );
    _card = card;
    return card;
  }

  void _openSetup(FeatureContext context, SourceService service) =>
      unawaited(context.push<void>(PhoneSetupPage(service: service)));

  Future<void> _openFromNotice(
    FeatureContext context,
    String deviceId,
    int threadId,
  ) async {
    await context.reveal();
    _openMessages(context, deviceId, threadId: threadId);
  }

  void _openMessages(
    FeatureContext context,
    String deviceId, {
    int? threadId,
  }) {
    if (threadId != null) {
      _wantedThreads[deviceId] = threadId;
      _threadRequests.value++;
    }

    unawaited(context.openSection(deviceId, sectionId));
  }

  static String _nameOf(FeatureContext context, String deviceId) =>
      context.engine.displayNameOf(deviceId);
}

/// What the Settings row says about Messages.
typedef _SettingsState = ({String summary, bool isOn, bool needsAttention});
