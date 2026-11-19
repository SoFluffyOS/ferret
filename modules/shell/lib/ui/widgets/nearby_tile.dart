import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:protocol/protocol.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/action_pair.dart';
import 'package:shell/ui/widgets/comparison_code.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:transport/transport.dart';

/// An unpaired Ferret device on the network. Resting, it offers to pair;
/// while pairing, the same card shows the code and what to do next.
class NearbyTile extends StatelessWidget {
  const NearbyTile({
    super.key,
    required this.peer,
    required this.onPair,
    this.attempt,
    this.isFirst = false,
    this.onConfirm,
    this.onCancel,
    this.onDismiss,
  });

  final DiscoveredPeer peer;

  /// Pairing with this device, when it is the one being paired.
  final NearbyAttempt? attempt;

  /// The first device gets the screen's one primary button.
  final bool isFirst;
  final VoidCallback onPair;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final name = peer.announce.name;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            _Header(
              peer: peer,
              trailing: switch (attempt) {
                null => Button(
                  mainAxisSize: .min,
                  variant: switch (isFirst) {
                    true => .primary,
                    false => .ghost,
                  },
                  label: l10n.nearbyPair,
                  onPressed: onPair,
                ),
                _ => null,
              },
            ),
            ...switch (attempt) {
              null => const <Widget>[],
              NearbyConnecting() => [_Line(l10n.nearbyConnecting(name))],
              NearbyComparing(:final code, confirmedHere: false) => [
                Spacing.v12,
                ComparisonCode(code: code),
                Spacing.v8,
                _Line(l10n.nearbyCheckCode(name), centered: true),
                Spacing.v12,
                _Actions(
                  ghostLabel: l10n.cancel,
                  onGhost: onCancel,
                  primaryLabel: l10n.nearbyTheyMatch,
                  onPrimary: onConfirm,
                ),
              ],
              NearbyComparing(:final code, confirmedHere: true) => [
                Spacing.v12,
                ComparisonCode(code: code),
                Spacing.v8,
                _Line(l10n.nearbyTapThere(name), centered: true, strong: true),
                _Line(l10n.nearbyWaiting(name), centered: true),
              ],
              NearbyPaired() => [
                _Line(l10n.pairSuccess(name), tone: _Tone.good),
              ],
              NearbyFailed(:final reason) => [
                _Line(_describe(l10n, reason, name)),
                Spacing.v12,
                _Actions(
                  ghostLabel: l10n.cancel,
                  onGhost: onDismiss,
                  primaryLabel: l10n.nearbyTryAgain,
                  onPrimary: onPair,
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  String _describe(
    ShellLocalizations l10n,
    PairingFailure reason,
    String name,
  ) => switch (reason) {
    .timedOut => l10n.nearbyNoAnswer(name),
    .rejected => l10n.nearbyNotNow(name),
    .unreachable => l10n.nearbyUnreachable(name),
    .wrongDevice => l10n.pairFailedWrongDevice,
    .badProof => l10n.pairFailedBadProof,
    .expired => l10n.pairFailedExpired,
    .protocol || .cancelled => l10n.pairFailedProtocol,
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.peer, this.trailing});

  final DiscoveredPeer peer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final announce = peer.announce;
    final kind = _kindOf(announce.platform);

    return Row(
      children: [
        Icon(
          deviceIconFor(announce.formFactor, announce.platform),
          size: Spacing.d24,
          color: palette.text,
        ),
        Spacing.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                announce.name,
                style: typography.base1.copyWith(color: palette.text),
                overflow: .ellipsis,
              ),
              if (kind.isNotEmpty)
                Text(
                  kind,
                  style: typography.caption1.copyWith(
                    color: palette.mutedText,
                  ),
                ),
            ],
          ),
        ),
        if (trailing case final trailing?) ...[Spacing.h12, trailing],
      ],
    );
  }

  /// Product names, the same in every language.
  String _kindOf(Platform platform) => switch (platform) {
    .PLATFORM_ANDROID => 'Android',
    .PLATFORM_IOS => 'iPhone',
    .PLATFORM_MACOS => 'Mac',
    .PLATFORM_LINUX => 'Linux',
    .PLATFORM_WINDOWS => 'Windows',
    .PLATFORM_CLI => 'Terminal',
    _ => '',
  };
}

enum _Tone { muted, good }

class _Line extends StatelessWidget {
  const _Line(
    this.text, {
    this.centered = false,
    this.strong = false,
    this.tone = _Tone.muted,
  });

  final String text;
  final bool centered;
  final bool strong;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = switch ((strong, tone)) {
      (true, _) => palette.text,
      (_, .good) => palette.success,
      (_, .muted) => palette.mutedText,
    };

    return Padding(
      padding: EdgeInsets.only(top: Spacing.d4),
      child: Text(
        text,
        textAlign: switch (centered) {
          true => .center,
          false => .start,
        },
        style: context.fluffyTheme.typography.base2.copyWith(color: color),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.ghostLabel,
    required this.onGhost,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String ghostLabel;
  final VoidCallback? onGhost;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    return ActionPair(
      ghostLabel: ghostLabel,
      onGhost: onGhost,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
    );
  }
}
