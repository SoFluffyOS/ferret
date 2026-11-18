import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/comparison_code.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where pairing by QR code, link or address stands: waiting, the code to
/// compare, or how it ended. Draws nothing while no pairing is going on.
///
/// On an iPhone, a computer it can't reach is most often the Local Network
/// switch, so that failure comes with a way to Settings.
class PairingStatusCard extends StatelessWidget {
  const PairingStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<PairingViewModel, PairingState>(
      (viewModel) => viewModel.state,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    final Widget content = switch (state) {
      PairingIdle() => const SizedBox.shrink(),
      PairingConnecting() => Text(
        l10n.pairWaiting,
        style: typography.body2.copyWith(color: palette.mutedText),
      ),
      PairingComparing(:final code, :final confirmedHere) => Column(
        crossAxisAlignment: .stretch,
        children: [
          ComparisonCode(code: code),
          Spacing.v12,
          Text(
            switch (confirmedHere) {
              true => l10n.pairWaiting,
              false => l10n.pairCompareTitle,
            },
            textAlign: .center,
            style: typography.body2.copyWith(color: palette.mutedText),
          ),
          if (!confirmedHere) ...[
            Spacing.v12,
            Row(
              children: [
                Expanded(
                  child: Button(
                    variant: .ghost,
                    label: l10n.cancel,
                    onPressed: context.read<PairingViewModel>().cancel,
                  ),
                ),
                Spacing.h12,
                Expanded(
                  child: Button(
                    variant: .primary,
                    label: l10n.nearbyTheyMatch,
                    onPressed: context.read<PairingViewModel>().confirm,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      PairingDone(:final outcome) => Column(
        children: [
          Text(
            _describe(l10n, outcome),
            textAlign: .center,
            style: typography.base1.copyWith(
              color: switch (outcome) {
                Paired() => palette.success,
                PairingFailed() => palette.text,
              },
            ),
          ),
          if (_offersSettings(outcome)) ...[
            Spacing.v12,
            Button(
              mainAxisSize: .min,
              variant: .ghost,
              label: l10n.nearbyOpenSettings,
              onPressed: () => unawaited(launchUrl(Uri.parse('app-settings:'))),
            ),
          ],
        ],
      ),
    };

    if (state is PairingIdle) {
      return content;
    }

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d8, bottom: Spacing.d8),
      child: SurfaceCard(
        padding: EdgeInsets.all(Spacing.d16),
        child: content,
      ),
    );
  }

  bool _offersSettings(PairingOutcome outcome) =>
      defaultTargetPlatform == .iOS &&
      outcome is PairingFailed &&
      outcome.reason == .unreachable;

  String _describe(ShellLocalizations l10n, PairingOutcome outcome) =>
      switch (outcome) {
        Paired(:final device) => l10n.pairSuccess(device.name),
        PairingFailed(:final reason) => switch (reason) {
          .unreachable when defaultTargetPlatform == .iOS =>
            l10n.pairFailedUnreachableIphone,
          .unreachable => l10n.pairFailedUnreachable,
          .rejected => l10n.pairFailedRejected,
          .expired => l10n.pairFailedExpired,
          .badProof => l10n.pairFailedBadProof,
          .wrongDevice => l10n.pairFailedWrongDevice,
          .timedOut => l10n.pairFailedTimedOut,
          .cancelled => l10n.pairFailedProtocol,
          .protocol => l10n.pairFailedProtocol,
        },
      };
}
