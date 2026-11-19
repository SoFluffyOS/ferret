import 'dart:async';

import 'package:actions/feature/feature.dart';
import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/services/services.dart';
import 'package:actions/ui/action_prompter.dart';
import 'package:actions/ui/actions_activity.dart';
import 'package:actions/ui/frames/frames.dart';
import 'package:actions/view_models/view_models.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of computer actions. On a computer: the question and the
/// countdown (dialog, notice and home card), "Your actions" in Settings,
/// a switch per action on each device's page, and a line in Activity for
/// what ran. On the device that asks: the computer's actions on its page,
/// and how each request went.
class ActionsFeatureUi extends FeatureUi {
  ActionsFeatureUi({ActionsFeature? feature})
    : feature = feature ?? ActionsFeature();

  @override
  final ActionsFeature feature;

  late final ActionsViewModel viewModel = ActionsViewModel(feature);
  ActionNotices? _notices;
  ActionPrompter? _prompter;
  VoidCallback? _revealOnAsk;

  /// When what the app was last brought to the front for started.
  DateTime? _revealedFor;

  @override
  String get featureId => ActionsFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    ActionsLocalizations.delegate,
  ];

  @override
  List<NoticeCategory> get noticeCategories =>
      ActionNotices.categories(platformActionsL10n());

  @override
  String title(BuildContext context) => context.actionsL10n.title;

  @override
  IconData get icon => LucideIcons.power;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    final actionsHost = feature.actionsHost;
    if (actionsHost == null) {
      return;
    }

    if (feature.leaveLock case final leaveLock?) {
      leaveLock.watchReconnecting(
        (deviceId) => context.engine.devices.any(
          (status) => status.device.id == deviceId && status.isReconnecting,
        ),
      );
    }

    _notices = ActionNotices(
      host: actionsHost,
      leaveLock: feature.leaveLock,
      notifier: context.notifier,
      l10n: platformActionsL10n(),
      reveal: context.reveal,
    )..start();
    _prompter = ActionPrompter(
      viewModel: viewModel,
      navigatorKey: context.navigatorKey,
    )..start();
    void revealOnAsk() => _revealWhenAsked(context);
    _revealOnAsk = revealOnAsk;
    viewModel.addListener(revealOnAsk);
    revealOnAsk();
  }

  @override
  Listenable get uiChanges => viewModel;

  /// Only while a device asks or a restart or shut down counts down.
  @override
  bool hasHomeCard(FeatureContext feature) => viewModel.needsOwner;

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) {
    if (!viewModel.offersActions) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: const OwnerCardFrame(),
    );
  }

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) => [
    ...recordActivity(
      context.actionsL10n,
      viewModel.recent,
      commandSeconds: viewModel.commandSeconds,
      onDismiss: viewModel.dismissRecord,
    ),
    ...leaveActivity(
      context.actionsL10n,
      viewModel.leaveRecords,
      lockAfterMinutes: viewModel.lockAfterMinutes,
      onDismiss: viewModel.dismissLeaveRecord,
    ),
    ...outgoingActivity(
      context.actionsL10n,
      viewModel.outgoing,
      onDismiss: viewModel.dismissOutgoing,
    ),
  ];

  /// On the asking device: what [device] offers. On a computer: whether
  /// [device] may ask at all.
  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    final l10n = platformActionsL10n();
    final name = device.device.name;
    final offers =
        session
            .remoteFeature(featureId)
            ?.flags
            .contains(ActionsFeature.runFlag) ??
        false;
    if (offers) {
      final count = viewModel.actionsOf(device.device.id).length;
      return switch (count) {
        0 => FeatureHealth(
          .off,
          reason: l10n.healthRemoteOff(name),
          help: l10n.healthRemoteOffHelp(name),
        ),
        _ => FeatureHealth(.ok, reason: l10n.healthOffers(count, name)),
      };
    }

    if (!viewModel.offersActions || !session.supports(featureId)) {
      return null;
    }

    if (!viewModel.enabled) {
      return FeatureHealth(
        .off,
        reason: l10n.healthHostOff(ComputerKind.here.name),
        help: l10n.healthHostOffHelp,
      );
    }

    return FeatureHealth(.ok, reason: l10n.healthHostAsks);
  }

  /// A computer's actions on its page, under a "This Mac" title.
  @override
  Widget? buildDeviceGroup(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final deviceId = device.device.id;
    if (viewModel.actionsOf(deviceId).isEmpty) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: DeviceActionsFrame(
        deviceId: deviceId,
        deviceName: device.device.name,
        computer: ComputerKind.of(device.device.platform),
      ),
    );
  }

  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    if (!viewModel.offersActions) {
      return const [];
    }

    final l10n = context.actionsL10n;
    final ownCount = viewModel.custom.length;

    return [
      FeatureSettings(
        group: .control,
        title: l10n.title,
        child: ChangeNotifierProvider.value(
          value: viewModel,
          child: const ActionsSettingsFrame(),
        ),
        summary: switch ((viewModel.enabled, ownCount)) {
          (false, _) => l10n.summaryOff,
          (true, 0) => l10n.summaryOn,
          (true, final count) => l10n.summaryOwn(count),
        },
        isOn: viewModel.enabled,
      ),
    ];
  }

  /// On a computer, what [device] may run without asking: one switch per
  /// action, the three sound actions as one. For an Android phone, also
  /// whether this computer locks when it leaves.
  @override
  List<DevicePermission> devicePermissions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) => [
    ..._actionPermissions(context, device),
    ?_leavePermission(context, device),
  ];

  List<DevicePermission> _actionPermissions(
    BuildContext context,
    DeviceStatus device,
  ) {
    final actionsHost = feature.actionsHost;
    final deviceId = device.device.id;
    if (actionsHost == null || !actionsHost.enabled) {
      return const [];
    }

    final asksOrMay =
        (device.session?.supports(featureId) ?? false) ||
        feature.settings.allowedFor(deviceId).isNotEmpty;
    if (!asksOrMay) {
      return const [];
    }

    final l10n = context.actionsL10n;
    return [
      for (final action in actionsHost.grantable)
        DevicePermission(
          label: l10n.permissionLabelOf(action, ComputerKind.here),
          value: actionsHost.isAllowed(deviceId, action),
          onChanged: (value) => unawaited(
            actionsHost.setAllowed(deviceId, action, allowed: value),
          ),
        ),
    ];
  }

  DevicePermission? _leavePermission(
    BuildContext context,
    DeviceStatus device,
  ) {
    if (!viewModel.canWatch(device.device.platform)) {
      return null;
    }

    final l10n = context.actionsL10n;
    final deviceId = device.device.id;
    return DevicePermission(
      label: l10n.leaveSwitch(
        feature.host.displayNameOf(deviceId),
        ComputerKind.here.name,
      ),
      detail: l10n.leavePermissionDetail(viewModel.lockAfterMinutes),
      value: viewModel.locksWhenGone(deviceId),
      onChanged: (value) =>
          unawaited(viewModel.setLocksWhenGone(deviceId, locks: value)),
    );
  }

  /// Stops listening, for tests and hot restarts.
  Future<void> dispose() async {
    await _notices?.dispose();
    _prompter?.dispose();
    if (_revealOnAsk case final revealOnAsk?) {
      viewModel.removeListener(revealOnAsk);
    }

    viewModel.dispose();
  }

  /// Brings Ferret to the front once per question and per countdown, so
  /// the owner sees it right away.
  void _revealWhenAsked(FeatureContext context) {
    final startedAt =
        viewModel.countdown?.startedAt ??
        viewModel.leaveCountdown?.startedAt ??
        viewModel.pending?.askedAt;
    if (startedAt == null || _revealedFor == startedAt) {
      return;
    }

    _revealedFor = startedAt;
    unawaited(context.reveal());
  }
}
