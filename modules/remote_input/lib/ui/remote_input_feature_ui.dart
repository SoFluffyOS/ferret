import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
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
import 'package:remote_input/ui/remote_input_activity.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The app side of Remote input. On a phone: "Use as touchpad" on each
/// computer, and the touchpad page. On a computer: the consent dialog and
/// notice, the "Pixel is controlling this Mac · Stop" line in Activity and
/// its notice, the line once it is over, and Settings with revoke and
/// history.
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

  /// While a device controls this computer, the menubar icon says so.
  @override
  FeatureBusy? busyState(FeatureContext feature) =>
      switch (hostViewModel.active) {
        final active? => FeatureBusy(controlledBy: active.deviceName),
        null => null,
      };

  /// Only while a device asks, or couldn't control this computer for a
  /// missing permission. Being controlled is a line in [activity].
  @override
  bool hasHomeCard(FeatureContext feature) => hostViewModel.hasCard;

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) =>
      remoteInputActivity(
        context.remoteInputL10n,
        hostViewModel,
        thisComputer: switch (defaultTargetPlatform) {
          .macOS => .mac,
          .windows => .windows,
          _ => .linux,
        },
      );

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

  /// On a phone: whether this phone can be [device]'s touchpad, from how
  /// the last try went. On a computer: whether [device] may control it.
  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    final l10n = platformRemoteInputL10n();
    if (this.feature.canControlDevice(session)) {
      return _touchpadHealth(l10n, device.device);
    }

    if (hostViewModel.isAvailable && _isController(session)) {
      return _hostHealth(l10n, device.device.id);
    }

    return null;
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
        id: 'remote_input.touchpad',
        label: context.remoteInputL10n.useAsTouchpad,
        icon: LucideIcons.mousePointer2,
        onPressed: () => unawaited(_openTouchpad(feature, device)),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    final sections = [
      if (hostViewModel.isAvailable) _hostSettings(),
      if (this.feature.canControl) _touchpadSettings(),
    ];
    if (sections.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, section) in sections.indexed) ...[
          if (index > 0) Spacing.v24,
          section,
        ],
      ],
    );
  }

  /// A computer gets "Pointer and keyboard" (being controlled), a phone
  /// gets "Touchpad". Neither is called Control, which is the page's name.
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final l10n = context.remoteInputL10n;

    return [
      if (hostViewModel.isAvailable)
        FeatureSettings(
          group: .control,
          title: l10n.settingsHostTitle,
          child: _hostSettings(),
          summary: _hostSummary(l10n),
          isOn: hostViewModel.enabled && _hostIsReady,
          needsAttention: hostViewModel.lostAccess,
        ),
      if (this.feature.canControl)
        FeatureSettings(
          group: .control,
          title: l10n.settingsTouchpadTitle,
          child: _touchpadSettings(),
        ),
    ];
  }

  /// On a computer, whether [device] may control it without asking. Shown
  /// for phones, and for any device that was allowed before.
  @override
  List<DevicePermission> devicePermissions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final deviceId = device.device.id;
    final settings = this.feature.settings;
    final allowed = settings.isAlwaysAllowed(deviceId);
    final applies = allowed || _isController(device.session);
    if (!hostViewModel.isAvailable || !applies) {
      return const [];
    }

    final l10n = context.remoteInputL10n;
    return [
      DevicePermission(
        label: l10n.permissionAlways(_thisComputer.name),
        detail: switch (settings.enabled) {
          true => l10n.permissionAlwaysDetail,
          false => l10n.permissionAlwaysOff,
        },
        value: allowed,
        onChanged: (value) => unawaited(_setAlwaysAllowed(deviceId, value)),
      ),
    ];
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

  Widget _hostSettings() => ChangeNotifierProvider.value(
    value: hostViewModel,
    child: const HostSettingsFrame(),
  );

  Widget _touchpadSettings() => ChangeNotifierProvider.value(
    value: touchpadViewModel,
    child: const ControllerSettingsFrame(),
  );

  bool get _hostIsReady => hostViewModel.status?.isReady ?? false;

  HostKind get _thisComputer => switch (defaultTargetPlatform) {
    .macOS => .mac,
    .windows => .windows,
    _ => .linux,
  };

  /// Whether [session]'s device offers itself as a touchpad.
  bool _isController(Session? session) =>
      session
          ?.remoteFeature(featureId)
          ?.flags
          .contains(RemoteInputFeature.controllerFlag) ??
      false;

  String _hostSummary(RemoteInputLocalizations l10n) {
    if (!hostViewModel.enabled) {
      return l10n.summaryOff;
    }

    return switch (hostViewModel.status?.state) {
      .ready => l10n.summaryOn,
      .needsPermission => l10n.summaryNeedsAccess,
      _ => l10n.summaryUnavailable,
    };
  }

  /// Turning it off also ends that device's control, if it has it.
  Future<void> _setAlwaysAllowed(String deviceId, bool allowed) async {
    if (allowed) {
      await feature.settings.allow(deviceId);
      return;
    }

    await hostViewModel.revoke(deviceId);
  }

  FeatureHealth _touchpadHealth(
    RemoteInputLocalizations l10n,
    TrustedDevice device,
  ) {
    final name = device.name;
    final last = feature.client?.lastFor(device.id);

    return switch (last) {
      OutgoingControl(phase: .active) => FeatureHealth(
        .ok,
        reason: l10n.healthControlling(name),
      ),
      OutgoingControl(phase: .denied, denial: .needsPermission) =>
        FeatureHealth(
          .needsAttention,
          reason: l10n.healthNeedsPermission(name),
          help: l10n.healthNeedsPermissionHelp(name),
        ),
      OutgoingControl(phase: .denied, denial: .unsupported) => FeatureHealth(
        .off,
        reason: l10n.healthUnsupported(name),
        help: l10n.healthUnsupportedHelp(name),
      ),
      OutgoingControl(phase: .denied, denial: .turnedOff) => FeatureHealth(
        .off,
        reason: l10n.healthTurnedOff(name),
        help: l10n.healthTurnedOffHelp(name),
      ),
      OutgoingControl(phase: .denied, denial: .version) => FeatureHealth(
        .off,
        reason: l10n.healthVersion(name),
        help: l10n.healthVersionHelp(name),
      ),
      OutgoingControl(phase: .unreachable) => FeatureHealth(
        .failing,
        reason: l10n.healthNotAnswering(name),
        help: l10n.healthNotAnsweringHelp(name),
      ),
      OutgoingControl(always: true) => FeatureHealth(
        .ok,
        reason: l10n.healthAlways(name),
      ),
      _ => FeatureHealth(.ok, reason: l10n.healthAsksFirst(name)),
    };
  }

  FeatureHealth _hostHealth(RemoteInputLocalizations l10n, String deviceId) {
    final host = _thisComputer.name;
    if (!hostViewModel.enabled) {
      return FeatureHealth(
        .off,
        reason: l10n.healthHostOff(host),
        help: l10n.healthHostOffHelp,
      );
    }

    final state = hostViewModel.status?.state;
    if (state == .needsPermission) {
      return FeatureHealth(
        switch (hostViewModel.lostAccess) {
          true => .needsAttention,
          false => .off,
        },
        reason: l10n.healthHostNeedsAccess(host),
        help: l10n.healthHostNeedsAccessHelp,
        onFix: () => unawaited(hostViewModel.requestAccess()),
      );
    }

    if (state != .ready) {
      return FeatureHealth(
        .off,
        reason: l10n.healthHostUnavailable,
        help: l10n.healthHostUnavailableHelp,
      );
    }

    if (hostViewModel.active?.deviceId == deviceId) {
      return FeatureHealth(.ok, reason: l10n.healthHostControlling(host));
    }

    if (feature.settings.isAlwaysAllowed(deviceId)) {
      return FeatureHealth(.ok, reason: l10n.healthHostAlways(host));
    }

    return FeatureHealth(.ok, reason: l10n.healthHostAsks(host));
  }

  HostKind _hostKindOf(Platform platform) => switch (platform) {
    .PLATFORM_MACOS || .PLATFORM_IOS => HostKind.mac,
    .PLATFORM_WINDOWS => HostKind.windows,
    _ => HostKind.linux,
  };
}
