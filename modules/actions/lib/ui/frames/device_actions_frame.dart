import 'dart:async';

import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/ui/action_icon.dart';
import 'package:actions/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart' hide Action;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/actions.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "This Mac" on a computer's page, as its other devices see it: Sleep,
/// Restart, Shut down, the volume, then its owner's own actions. Restart
/// and Shut down ask "are you sure" here first. Shows nothing for a device
/// that offers no actions, and no "This Mac" title over its own actions
/// alone.
class DeviceActionsFrame extends StatelessWidget {
  const DeviceActionsFrame({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.computer,
  });

  final String deviceId;
  final String deviceName;
  final ComputerKind computer;

  static const _sound = {
    ActionKind.ACTION_KIND_MUTE,
    ActionKind.ACTION_KIND_VOLUME_DOWN,
    ActionKind.ACTION_KIND_VOLUME_UP,
  };

  @override
  Widget build(BuildContext context) {
    final actions = context.select<ActionsViewModel, List<Action>>(
      (viewModel) => viewModel.actionsOf(deviceId),
    );
    // Rebuilds the rows while an answer is awaited.
    context.select<ActionsViewModel, int>(
      (viewModel) => viewModel.outgoing.where((out) => out.isWaiting).length,
    );
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.actionsL10n;
    final power = [
      for (final action in actions)
        if (action.kind != .ACTION_KIND_CUSTOM && !_sound.contains(action.kind))
          action,
    ];
    final sound = [
      for (final action in actions)
        if (_sound.contains(action.kind)) action,
    ];
    final own = [
      for (final action in actions)
        if (action.kind == .ACTION_KIND_CUSTOM) action,
    ];
    final separatorIndent = PageInsets.row + IconTile.size + Spacing.d12;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (power.isNotEmpty || sound.isNotEmpty) ...[
          SectionTitle(l10n.groupTitle),
          GroupedCard(
            separatorIndent: separatorIndent,
            children: [
              for (final action in power) _ActionRow(this, action),
              if (sound.isNotEmpty) _VolumeRow(this, sound),
            ],
          ),
        ],
        if (own.isNotEmpty) ...[
          SectionTitle(l10n.groupYourActions),
          GroupedCard(
            separatorIndent: separatorIndent,
            children: [for (final action in own) _ActionRow(this, action)],
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(
            PageInsets.row,
            Spacing.d8,
            PageInsets.row,
            Spacing.d0,
          ),
          child: Text(
            l10n.groupHint(deviceName),
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: context.palette.mutedText,
            ),
          ),
        ),
      ],
    );
  }

  /// Runs [action], after "are you sure" for the ones the computer asked
  /// to confirm.
  Future<void> run(BuildContext context, Action action) async {
    final viewModel = context.read<ActionsViewModel>();
    if (action.confirm && !await _confirm(context, action)) {
      return;
    }

    await viewModel.run(deviceId, action);
  }

  Future<bool> _confirm(BuildContext context, Action action) async {
    final l10n = context.actionsL10n;
    final (title, message, positive) = switch (action.kind) {
      .ACTION_KIND_SHUT_DOWN => (
        l10n.confirmShutDownTitle(deviceName),
        l10n.confirmShutDownBody(deviceName),
        l10n.actionShutDown,
      ),
      _ => (
        l10n.confirmRestartTitle(deviceName),
        l10n.confirmRestartBody(deviceName),
        l10n.actionRestart,
      ),
    };
    final answer = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
      positiveText: positive,
      negativeText: l10n.cancel,
      barrierLabel: l10n.dismiss,
    );

    return answer == .positive;
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(this.frame, this.action);

  final DeviceActionsFrame frame;
  final Action action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.actionsL10n;
    final isWaiting = context.read<ActionsViewModel>().isWaiting(
      frame.deviceId,
      action.id,
    );

    return GroupedRow(
      key: ValueKey(action.id),
      title: switch (action.kind) {
        .ACTION_KIND_RESTART => l10n.restartEllipsis,
        .ACTION_KIND_SHUT_DOWN => l10n.shutDownEllipsis,
        _ => l10n.actionLabel(action.kind, action.title),
      },
      titleMaxLines: 2,
      leading: IconTile(
        icon: actionIcon(action.kind),
        color: switch (action.kind) {
          .ACTION_KIND_SLEEP => .indigo,
          .ACTION_KIND_RESTART => .orange,
          .ACTION_KIND_SHUT_DOWN => .pink,
          _ => .grey,
        },
      ),
      trailing: switch (isWaiting) {
        true => FluffySpinner(size: Spacing.d16),
        false => null,
      },
      onTap: switch (isWaiting) {
        true => null,
        false => () => unawaited(frame.run(context, action)),
      },
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow(this.frame, this.actions);

  final DeviceActionsFrame frame;
  final List<Action> actions;

  static const _order = [
    ActionKind.ACTION_KIND_MUTE,
    ActionKind.ACTION_KIND_VOLUME_DOWN,
    ActionKind.ACTION_KIND_VOLUME_UP,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.actionsL10n;
    final buttons = [
      for (final kind in _order)
        for (final action in actions)
          if (action.kind == kind) action,
    ];

    return GroupedRow(
      title: l10n.actionVolume,
      leading: const IconTile(icon: LucideIcons.volume2, color: .teal),
      trailing: Row(
        mainAxisSize: .min,
        children: [
          for (final (index, action) in buttons.indexed) ...[
            if (index > 0) Spacing.h8,
            GhostButton(
              key: ValueKey(action.id),
              mainAxisSize: .min,
              // An icon alone needs no text-sized padding; with it the
              // three buttons squeeze "Volume" apart on a phone or tablet.
              padding: EdgeInsets.symmetric(
                horizontal: Spacing.d12,
                vertical: Spacing.d8,
              ),
              tooltip: l10n.actionLabel(action.kind, action.title),
              semanticLabel: l10n.actionLabel(action.kind, action.title),
              onPressed: () => unawaited(frame.run(context, action)),
              child: Icon(actionIcon(action.kind), size: Spacing.d16),
            ),
          ],
        ],
      ),
    );
  }
}
