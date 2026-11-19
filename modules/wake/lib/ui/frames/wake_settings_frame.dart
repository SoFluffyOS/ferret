import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_wake/ferret_wake.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:wake/l10n/l10n.dart';
import 'package:wake/ui/widgets/widgets.dart';
import 'package:wake/view_models/view_models.dart';

/// Wake-on-LAN in a computer's Settings: whether this computer can be
/// woken, by which card, the two switches, and how to turn it on.
class WakeSettingsFrame extends StatelessWidget {
  const WakeSettingsFrame({super.key, required this.onHelp});

  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final cards = context.select<WakeViewModel, List<NetworkCard>>(
      (viewModel) => viewModel.cards,
    );
    final shares = context.select<WakeViewModel, bool>(
      (viewModel) => viewModel.shares,
    );
    final relays = context.select<WakeViewModel, bool>(
      (viewModel) => viewModel.relays,
    );
    final viewModel = context.read<WakeViewModel>();
    final l10n = context.wakeL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return GroupedCard(
      children: [
        if (cards.isEmpty)
          GroupedCell(
            child: Text(
              l10n.cardNone,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ),
        for (final card in cards)
          GroupedCell(
            child: CardLine(link: card.link, setting: card.setting),
          ),
        SettingSwitchRow(
          title: l10n.settingsShare,
          body: l10n.settingsShareBody,
          value: shares,
          onChanged: (value) => unawaited(viewModel.setShares(value)),
        ),
        SettingSwitchRow(
          title: l10n.settingsRelay,
          body: l10n.settingsRelayBody,
          value: relays,
          onChanged: (value) => unawaited(viewModel.setRelays(value)),
        ),
        GroupedCell(
          child: Align(
            alignment: .centerLeft,
            child: Button(
              variant: .ghost,
              mainAxisSize: .min,
              label: l10n.howToTurnOn,
              onPressed: onHelp,
            ),
          ),
        ),
      ],
    );
  }
}
