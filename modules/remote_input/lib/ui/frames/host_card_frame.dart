import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This computer's card: a device asking for control, the "Controlled by
/// Pixel" indicator with Stop, a request that failed for a missing
/// permission, and the audit line once it is over.
class HostCardFrame extends StatelessWidget {
  const HostCardFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = context.select<HostViewModel, ConsentRequest?>(
      (viewModel) => viewModel.pending,
    );
    final active = context.select<HostViewModel, ActiveControl?>(
      (viewModel) => viewModel.active,
    );
    final permissionAsk = context.select<HostViewModel, PermissionAsk?>(
      (viewModel) => viewModel.permissionAsk,
    );
    final record = context.select<HostViewModel, ControlRecord?>(
      (viewModel) => viewModel.lastRecord,
    );
    final cards = [
      if (pending != null) _PendingCard(pending: pending),
      if (active != null) _ActiveCard(active: active),
      if (permissionAsk != null) _PermissionCard(ask: permissionAsk),
      if (record != null && active == null) _RecordCard(record: record),
    ];
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, card) in cards.indexed) ...[
          if (index > 0) Spacing.v8,
          card,
        ],
      ],
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.pending});

  final ConsentRequest pending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.remoteInputL10n;
    final viewModel = context.read<HostViewModel>();

    return FeatureCard(
      icon: LucideIcons.mousePointerClick,
      iconTone: .accent,
      title: l10n.consentTitle(pending.deviceName),
      subtitle: l10n.consentBody(pending.deviceName),
      actions: [
        Button(
          variant: .primary,
          label: l10n.allowAlways,
          onPressed: () => unawaited(viewModel.answer(.always)),
        ),
        Button(
          variant: .ghost,
          label: l10n.allowOnce,
          onPressed: () => unawaited(viewModel.answer(.allowOnce)),
        ),
        Button(
          variant: .ghost,
          label: l10n.dontAllow,
          onPressed: () => unawaited(viewModel.answer(.deny)),
        ),
      ],
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.active});

  final ActiveControl active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.remoteInputL10n;

    return FeatureCard(
      icon: LucideIcons.mousePointer2,
      iconTone: .warning,
      title: l10n.controlledBy(active.deviceName),
      subtitle: l10n.since(active.startedAt),
      actions: [
        Button(
          variant: .primary,
          label: l10n.stop,
          onPressed: () => unawaited(context.read<HostViewModel>().stop()),
        ),
      ],
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.ask});

  final PermissionAsk ask;

  @override
  Widget build(BuildContext context) {
    final l10n = context.remoteInputL10n;
    final viewModel = context.read<HostViewModel>();

    return FeatureCard(
      icon: LucideIcons.shieldAlert,
      iconTone: .danger,
      title: l10n.permissionTitle(ask.deviceName),
      subtitle: l10n.permissionBody(ask.deviceName),
      trailing: _DismissButton(
        label: l10n.dismiss,
        onTap: viewModel.dismissPermissionAsk,
      ),
      actions: [
        Button(
          variant: .primary,
          label: l10n.openSettings,
          onPressed: () => unawaited(viewModel.requestAccess()),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final ControlRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.remoteInputL10n;

    return FeatureCard(
      icon: LucideIcons.history,
      iconTone: .muted,
      title: l10n.title,
      subtitle: l10n.audit(record),
      trailing: _DismissButton(
        label: l10n.dismiss,
        onTap: context.read<HostViewModel>().dismissRecord,
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tappable(
    tooltip: label,
    onTap: onTap,
    child: Icon(
      LucideIcons.x,
      size: Spacing.d16,
      color: context.palette.mutedText,
    ),
  );
}
