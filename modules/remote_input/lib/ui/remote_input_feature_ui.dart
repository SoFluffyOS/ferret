import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart' show Platform;
import 'package:provider/provider.dart';
import 'package:remote_input/feature/remote_input_feature.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/services/services.dart';
import 'package:remote_input/ui/consent_prompter.dart';
import 'package:remote_input/ui/frames/frames.dart';
import 'package:remote_input/ui/pages/pages.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The app side of Remote input. On a phone: "Use as touchpad" on each
/// computer, and the touchpad page. On a computer: the consent dialog and
/// notice, the "Controlled by Pixel · Stop" card and notice, the audit
/// line, and Settings with revoke and history.
class RemoteInputFeatureUi extends FeatureUi {
  RemoteInputFeatureUi({RemoteInputFeature? feature})
    : feature = feature ?? RemoteInputFeature();

  @override
  final RemoteInputFeature feature;

  late final HostViewModel hostViewModel = HostViewModel(feature);
  late final TouchpadViewModel touchpadViewModel = TouchpadViewModel(feature);
  ControlNotices? _notices;
  ConsentPrompter? _prompter;
  VoidCallback? _revealOnAsk;

  /// When the request the app was last brought to the front for was made.
  DateTime? _revealedFor;

  @override
  String get featureId => RemoteInputFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    RemoteInputLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories =>
      ControlNotices.categories(platformRemoteInputL10n());

  @override
  String title(BuildContext context) => context.remoteInputL10n.title;

  @override
  IconData get icon => LucideIcons.mousePointer2;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    final controlHost = feature.controlHost;
    if (controlHost == null) {
      return;
    }

    _notices = ControlNotices(
      host: controlHost,
      notifier: context.notifier,
      l10n: platformRemoteInputL10n(),
      reveal: context.reveal,
    )..start();
    _prompter = ConsentPrompter(
      viewModel: hostViewModel,
      navigatorKey: context.navigatorKey,
    )..start();
    void revealOnAsk() => _revealWhenAsked(context);
    _revealOnAsk = revealOnAsk;
    hostViewModel.addListener(revealOnAsk);
    revealOnAsk();
  }

  @override
  Listenable get uiChanges => hostViewModel;

  /// Only while a device asks, controls this computer, couldn't for a
  /// missing permission, or just stopped.
  @override
  bool hasHomeCard(FeatureContext feature) => hostViewModel.hasCard;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) {
    if (!hostViewModel.isAvailable) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: hostViewModel,
      child: const HostCardFrame(),
    );
  }

  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null || !this.feature.canControlDevice(session)) {
      return null;
    }

    final name = device.device.name;
    final l10n = platformRemoteInputL10n();
    final last = this.feature.client?.lastFor(device.device.id);
    if (last == null || last.phase != .denied) {
      return null;
    }

    return switch (last.denial) {
      .needsPermission => FeatureHealth(
        .needsAttention,
        reason: l10n.healthNeedsPermission(name),
      ),
      .unsupported => FeatureHealth(.off, reason: l10n.healthUnsupported(name)),
      .turnedOff => FeatureHealth(.off, reason: l10n.healthTurnedOff(name)),
      _ => null,
    };
  }

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final session = device.session;
    if (session == null || !this.feature.canControlDevice(session)) {
      return const [];
    }

    return [
      FeatureAction(
        label: context.remoteInputL10n.useAsTouchpad,
        icon: LucideIcons.mousePointer2,
        onPressed: () => unawaited(_openTouchpad(feature, device)),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    final sections = [
      if (hostViewModel.isAvailable)
        ChangeNotifierProvider.value(
          value: hostViewModel,
          child: const HostSettingsFrame(),
        ),
      if (this.feature.canControl)
        ChangeNotifierProvider.value(
          value: touchpadViewModel,
          child: const ControllerSettingsFrame(),
        ),
    ];
    if (sections.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, section) in sections.indexed) ...[
          if (index > 0) Spacing.v8,
          section,
        ],
      ],
    );
  }

  /// Stops listening, for tests and hot restarts.
  Future<void> dispose() async {
    await _notices?.dispose();
    _prompter?.dispose();
    if (_revealOnAsk case final revealOnAsk?) {
      hostViewModel.removeListener(revealOnAsk);
    }

    hostViewModel.dispose();
    touchpadViewModel.dispose();
  }

  /// Brings Ferret to the front once per request, so the owner sees the
  /// question, or why it failed, right away.
  void _revealWhenAsked(FeatureContext context) {
    final askedAt =
        hostViewModel.pending?.askedAt ?? hostViewModel.permissionAsk?.askedAt;
    if (askedAt == null || _revealedFor == askedAt) {
      return;
    }

    _revealedFor = askedAt;
    unawaited(context.reveal());
  }

  Future<void> _openTouchpad(
    FeatureContext context,
    DeviceStatus device,
  ) async {
    final deviceId = device.device.id;
    unawaited(touchpadViewModel.start(deviceId));
    await context.push<void>(
      ChangeNotifierProvider.value(
        value: touchpadViewModel,
        child: TouchpadPage(
          deviceId: deviceId,
          deviceName: device.device.name,
          hostKind: _hostKindOf(device.device.platform),
        ),
      ),
    );
  }

  HostKind _hostKindOf(Platform platform) => switch (platform) {
    .PLATFORM_MACOS || .PLATFORM_IOS => HostKind.mac,
    .PLATFORM_WINDOWS => HostKind.windows,
    _ => HostKind.linux,
  };
}
