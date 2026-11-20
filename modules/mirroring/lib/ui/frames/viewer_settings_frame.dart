import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';

/// The computer's screen settings: two switches for the ways that need
/// no Ferret on the other device, and the history of the screens shown.
/// Setting those ways up happens on the mirror stage, where it is needed.
class ViewerSettingsFrame extends StatelessWidget {
  const ViewerSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.select<ViewerViewModel, List<MirrorRecord>>(
      (viewModel) => viewModel.history,
    );
    final hasCable = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.hasCable,
    );
    final lookForCable = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.lookForCable,
    );
    final receivers = context.select<ViewerViewModel, List<ReceiverSwitch>>(
      (viewModel) => viewModel.receivers,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;

    final switches = [
      if (hasCable)
        SettingSwitchRow(
          title: l10n.lookForCableTitle,
          badge: const MirroringBetaTag(.cableScreen),
          body: l10n.lookForCableBody,
          value: lookForCable,
          onChanged: (value) => unawaited(viewModel.setLookForCable(value)),
        ),
      for (final receiver in receivers)
        SettingSwitchRow(
          title: l10n.receiverTitle(receiver.receiverId),
          badge: const MirroringBetaTag(.screenReceiver),
          body: l10n.receiverBody(receiver.receiverId),
          value: receiver.on,
          onChanged: (value) => unawaited(
            viewModel.setReceiverOn(receiver.receiverId, value),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        if (switches.isNotEmpty) GroupedCard(children: switches),
        HistoryList(
          history: history,
          onClear: () => unawaited(viewModel.clearHistory()),
        ),
      ],
    );
  }
}
