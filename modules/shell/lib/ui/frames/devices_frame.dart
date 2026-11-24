import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/frames/tips_frame.dart';
import 'package:shell/ui/widgets/widgets.dart';

/// Your devices, connected ones first, each with what to do with it right
/// on its row. With many devices, the offline ones fold into one line.
class DevicesFrame extends StatefulWidget {
  const DevicesFrame({super.key, required this.onOpen, required this.onFix});

  final void Function(DeviceStatus status) onOpen;
  final void Function(DeviceStatus status) onFix;

  /// How many actions fit on a row.
  static const actionsShown = 3;

  /// From this many devices on, offline ones fold away.
  static const foldsFrom = 4;

  /// The clipboard's action, which ⌘V on a row runs.
  static const sendClipboardId = 'clipboard.send';

  @override
  State<DevicesFrame> createState() => _DevicesFrameState();
}

class _DevicesFrameState extends State<DevicesFrame> {
  bool _showsOffline = false;
  bool _confirmsRemoval = false;

  /// Each device's buttons the last time it was connected, shown greyed
  /// out while it reconnects so the row keeps its height.
  final Map<String, List<FeatureAction>> _lastActions = {};

  @override
  Widget build(BuildContext context) {
    final devices = context.select<EngineHost, List<DeviceStatus>>(
      (host) => host.devices,
    );
    if (devices.isEmpty) {
      return const SizedBox.shrink();
    }

    final scope = ShellScope.of(context);
    final l10n = context.shellL10n;
    final offlineCount = devices
        .where((status) => !status.isConnected && !status.isReconnecting)
        .length;
    final folds =
        devices.length >= DevicesFrame.foldsFrom &&
        offlineCount > 1 &&
        !_showsOffline;
    final shown = switch (folds) {
      true => [
        for (final status in devices)
          if (status.isConnected || status.isReconnecting) status,
      ],
      false => devices,
    };
    final firstConnected = devices.where((status) => status.isConnected);
    final preferences = context.read<EngineHost>().preferences;
    final replaced = context.select<EngineHost, Set<String>>(
      (host) => {for (final successor in host.successors) successor.old.id},
    );
    final stale = switch (folds) {
      true => const <DeviceStatus>[],
      false => [
        for (final status in devices)
          if (preferences.isStale(status) &&
              !replaced.contains(status.device.id))
            status,
      ],
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        SectionTitle(l10n.homeYourDevices),
        for (final (index, status) in shown.indexed) ...[
          FeatureChangesListener(
            key: ValueKey(status.device.id),
            features: scope.features,
            builder: (context) => KeyboardLine(
              keys: _keysFor(context, scope, status),
              builder: (context, focusNode) {
                final attention = _attentionFor(context, scope, status);

                return DeviceDropHover(
                  target: WindowDropTargets.device(status),
                  child: ConnectionAnnouncer(
                    status: status,
                    child: DeviceTile(
                      status: status,
                      focusNode: focusNode,
                      actions: _actionsFor(context, scope, status),
                      hasPrimary:
                          index == 0 && !_feedHoldsPrimary(context, scope),
                      attention: attention?.title,
                      attentionReason: attention?.health.reason,
                      offlineStatus: _offlineStatusFor(context, scope, status),
                      onTap: () => widget.onOpen(status),
                      onFix: () => widget.onFix(status),
                      isPinned: preferences.isPinned(status.device.id),
                    ),
                  ),
                );
              },
            ),
          ),
          if (index == 0 && status.isConnected)
            TipsFrame(device: firstConnected.first),
        ],
        if (folds)
          FooterHint(
            text: l10n.devicesOffline(offlineCount),
            actionLabel: l10n.devicesShow,
            onAction: () => setState(() => _showsOffline = true),
          ),
        if (stale.isNotEmpty && !_confirmsRemoval)
          FooterHint(
            text: l10n.devicesStale(stale.length),
            actionLabel: l10n.devicesStaleReview,
            onAction: () => setState(() => _confirmsRemoval = true),
          ),
        if (stale.isNotEmpty && _confirmsRemoval)
          StaleDevicesCard(
            names: [for (final status in stale) status.device.name],
            here: l10n.here(scope.featureContext.engine.device),
            onRemove: () => unawaited(_remove(scope, stale)),
            onCancel: () => setState(() => _confirmsRemoval = false),
          ),
      ],
    );
  }

  /// Forgets [stale] on this device only: the user's other devices may
  /// still use them.
  Future<void> _remove(ShellScope scope, List<DeviceStatus> stale) async {
    final engine = scope.featureContext.engine;
    final preferences = context.read<EngineHost>().preferences;
    setState(() => _confirmsRemoval = false);

    for (final status in stale) {
      await engine.unpair(status.device.id);
      await preferences.forget(status.device.id);
    }
  }

  /// Something waiting for an answer or going on right now, such as a call
  /// ringing, takes the screen's one filled button from the device row.
  bool _feedHoldsPrimary(BuildContext context, ShellScope scope) =>
      ActivityFeed.holdsPrimary(context, scope.features, scope.featureContext);

  /// ⌘V (Ctrl+V off a Mac) on a connected device's row sends it the
  /// clipboard.
  Map<SingleActivator, VoidCallback> _keysFor(
    BuildContext context,
    ShellScope scope,
    DeviceStatus status,
  ) {
    if (!status.isConnected) {
      return const {};
    }

    for (final feature in scope.features) {
      for (final action in feature.deviceActions(
        context,
        scope.featureContext,
        status,
      )) {
        if (action case FeatureAction(
          id: DevicesFrame.sendClipboardId,
          :final onPressed?,
        )) {
          final usesCommand = switch (defaultTargetPlatform) {
            .macOS || .iOS => true,
            _ => false,
          };
          final paste = SingleActivator(
            LogicalKeyboardKey.keyV,
            meta: usesCommand,
            control: !usesCommand,
          );

          return {paste: onPressed};
        }
      }
    }

    return const {};
  }

  /// The actions features marked for Home, in their order, with the one
  /// used most with this device first once it is a habit.
  List<FeatureAction> _actionsFor(
    BuildContext context,
    ShellScope scope,
    DeviceStatus status,
  ) {
    if (status.isReconnecting) {
      return [
        for (final action in _lastActions[status.device.id] ?? const [])
          FeatureAction(
            id: action.id,
            label: action.label,
            tooltip: action.tooltip,
            icon: action.icon,
            onPressed: null,
          ),
      ];
    }

    if (!status.isConnected) {
      return [
        if (status.versionMismatch == null)
          for (final feature in scope.features)
            ...feature.offlineActions(context, scope.featureContext, status),
      ];
    }

    final ordered = <(int, FeatureAction)>[
      for (final feature in scope.features)
        for (final action in feature.deviceActions(
          context,
          scope.featureContext,
          status,
        ))
          if (action.homeOrder case final order?) (order, action),
    ]..sort((a, b) => a.$1.compareTo(b.$1));

    final usage = DeviceActionUsage(scope.featureContext.engine.settings);
    final arranged = usage.arrange(status.device.id, [
      for (final (_, action) in ordered) action,
    ]);

    final shown = arranged.take(DevicesFrame.actionsShown).toList();
    _lastActions[status.device.id] = shown;
    return shown;
  }

  /// What a feature is doing with this offline device, such as waking it.
  String? _offlineStatusFor(
    BuildContext context,
    ShellScope scope,
    DeviceStatus status,
  ) {
    if (status.isConnected) {
      return null;
    }

    for (final feature in scope.features) {
      if (feature.offlineStatus(context, scope.featureContext, status)
          case final line?) {
        return line;
      }
    }

    return null;
  }

  /// The first feature that is on and not working with this device.
  ({String title, FeatureHealth health})? _attentionFor(
    BuildContext context,
    ShellScope scope,
    DeviceStatus status,
  ) => DeviceAttention.of(
    context,
    scope.features,
    scope.featureContext,
    status,
  ).firstOrNull;
}
