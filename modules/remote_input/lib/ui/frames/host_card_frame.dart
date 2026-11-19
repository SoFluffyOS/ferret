import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// This computer's card, for what needs its owner: a device asking for
/// control, and a request that failed for a missing permission. Being
/// controlled, and having been, are lines in Activity.
class HostCardFrame extends StatelessWidget {
  const HostCardFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = context.select<HostViewModel, ConsentRequest?>(
      (viewModel) => viewModel.pending,
    );
    final permissionAsk = context.select<HostViewModel, PermissionAsk?>(
      (viewModel) => viewModel.permissionAsk,
    );
    final cards = [
      if (pending != null) _PendingCard(pending: pending),
      if (permissionAsk != null) _PermissionCard(ask: permissionAsk),
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
      icon: switch (pending.kind) {
        .control => LucideIcons.mousePointerClick,
        .lock => LucideIcons.lock,
      },
      iconTone: .accent,
      title: l10n.consentTitleOf(pending, HostKind.here),
      subtitle: l10n.consentBodyOf(pending),
      actions: [
        Button(
          mainAxisSize: .min,
          variant: .primary,
          label: l10n.allowAlways,
          onPressed: () => unawaited(viewModel.answer(.always)),
        ),
        Button(
          mainAxisSize: .min,
          variant: .ghost,
          label: l10n.allowOnce,
          onPressed: () => unawaited(viewModel.answer(.allowOnce)),
        ),
        Button(
          mainAxisSize: .min,
          variant: .ghost,
          label: l10n.dontAllow,
          onPressed: () => unawaited(viewModel.answer(.deny)),
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
          mainAxisSize: .min,
          variant: .primary,
          label: l10n.openSettings,
          onPressed: () => unawaited(viewModel.requestAccess()),
        ),
      ],
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
