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
import 'package:messages/ui/pages/pages.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The app side of Messages: setup on the phone; on computers the Messages
/// page, the home card with unread texts, notices with Reply, and Settings.
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

  @override
  final MessagesFeature feature;

  IncomingNotices? _notices;
  CardViewModel? _card;
  FeatureChanges? _changes;

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
  Listenable get uiChanges => _changes ??= FeatureChanges(
    switch (feature.sourceService) {
      final SourceService service => service.changes,
      null => feature.library.events,
    },
  );

  /// On the phone, only while Messages are on but SMS access is missing;
  /// on a computer, only once a paired phone shared its texts.
  @override
  bool hasHomeCard(FeatureContext feature) {
    if (this.feature.sourceService case final service?) {
      final access = service.access;
      return access.hasTelephony && service.settings.enabled && !access.canRead;
    }

    return _cardFor(feature).phones.isNotEmpty;
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

  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (this.feature.isSource ||
        session == null ||
        !MessagesFeature.isPhone(session)) {
      return null;
    }

    final strings = platformMessagesL10n();
    final name = device.device.name;
    return switch (this.feature.library.phone(device.device.id).readiness) {
      .ready => FeatureHealth(.ok, reason: strings.healthOk),
      .unreachable => FeatureHealth(
        .failing,
        reason: strings.healthUnreachable(name),
      ),
      .off => FeatureHealth(.off, reason: strings.healthOff(name)),
      .noAccess => FeatureHealth(
        .needsAttention,
        reason: strings.healthNoAccess,
      ),
      .checking || .offline => null,
    };
  }

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
        label: context.messagesL10n.title,
        icon: LucideIcons.messageSquare,
        onPressed: () => _openMessages(feature, deviceId),
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

  /// Stops showing notices.
  Future<void> dispose() async {
    await _notices?.stop();
    _notices = null;
    _card?.dispose();
    _changes?.dispose();
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
    unawaited(
      context.push<void>(
        MessagesPage(
          library: feature.library,
          deviceId: deviceId,
          phoneName: _nameOf(context, deviceId),
          initialThreadId: threadId,
          onThreadOpened: (openedThreadId) =>
              unawaited(_notices?.clear(deviceId, openedThreadId)),
        ),
      ),
    );
  }

  static String _nameOf(FeatureContext context, String deviceId) =>
      context.engine.trustStore[deviceId]?.name ?? deviceId;
}
