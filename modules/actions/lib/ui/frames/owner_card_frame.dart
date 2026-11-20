import 'dart:async';

import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/ui/action_icon.dart';
import 'package:actions/ui/widgets/widgets.dart';
import 'package:actions/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The computer's home card while actions need its owner: the countdown
/// with Cancel, or the device asking with its three answers.
class OwnerCardFrame extends StatelessWidget {
  const OwnerCardFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final countdown = context.select<ActionsViewModel, ActionCountdown?>(
      (viewModel) => viewModel.countdown,
    );
    final pending = context.select<ActionsViewModel, ActionAsk?>(
      (viewModel) => viewModel.pending,
    );
    if (countdown != null) {
      return _CountdownCard(countdown: countdown);
    }

    if (pending != null) {
      return _AskCard(ask: pending);
    }

    return const SizedBox.shrink();
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.countdown});

  final ActionCountdown countdown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.actionsL10n;
    final viewModel = context.read<ActionsViewModel>();

    return SecondsLeft(
      endsAt: countdown.endsAt,
      builder: (context, seconds) => FeatureCard(
        icon: actionIcon(countdown.action.kind),
        iconTone: .warning,
        title: l10n.countdownTitleOf(countdown, ComputerKind.here, seconds),
        subtitle: l10n.countdownBody(countdown.deviceName),
        actions: [
          Button(
            mainAxisSize: .min,
            variant: .primary,
            label: l10n.cancel,
            onPressed: viewModel.cancelCountdown,
          ),
        ],
      ),
    );
  }
}

class _AskCard extends StatelessWidget {
  const _AskCard({required this.ask});

  final ActionAsk ask;

  @override
  Widget build(BuildContext context) {
    final l10n = context.actionsL10n;
    final viewModel = context.read<ActionsViewModel>();
    final commandLine = ask.action.commandLine;

    return FeatureCard(
      icon: actionIcon(ask.action.kind),
      iconTone: .accent,
      title: l10n.consentTitleOf(ask, ComputerKind.here),
      subtitle: l10n.consentBody(ask.deviceName),
      children: [
        if (commandLine.isNotEmpty) ...[
          Text(
            l10n.consentCommandLabel,
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: context.palette.mutedText,
            ),
          ),
          Spacing.v4,
          CommandBlock(commandLine),
        ],
      ],
      actions: [
        Button(
          mainAxisSize: .min,
          variant: .primary,
          label: l10n.allowAlways,
          onPressed: () => unawaited(viewModel.answer(.always)),
        ),
        GhostButton(
          mainAxisSize: .min,
          label: l10n.allowOnce,
          onPressed: () => unawaited(viewModel.answer(.allowOnce)),
        ),
        GhostButton(
          mainAxisSize: .min,
          label: l10n.dontAllow,
          onPressed: () => unawaited(viewModel.answer(.deny)),
        ),
      ],
    );
  }
}
