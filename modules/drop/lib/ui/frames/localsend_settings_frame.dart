import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:drop/ui/widgets/widgets.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// LocalSend's settings: whether Ferret works with it at all, and whether
/// this device stays visible to LocalSend devices.
class LocalSendSettingsFrame extends StatelessWidget {
  const LocalSendSettingsFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DropViewModel>();
    final localSend = context.select<DropViewModel, bool>(
      (model) => model.localSendEnabled,
    );
    final receiveAlways = context.select<DropViewModel, bool>(
      (model) => model.receiveAlways,
    );
    final problem = context.select<DropViewModel, LocalSendProblem?>(
      (model) => model.receiveState.problem,
    );
    final l10n = context.dropL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          SettingSwitch(
            title: l10n.settingsLocalSend,
            body: l10n.settingsLocalSendBody,
            value: localSend,
            onChanged: viewModel.setLocalSendEnabled,
          ),
          if (localSend) ...[
            Spacing.v16,
            SettingSwitch(
              title: l10n.settingsReceiveAlways,
              body: l10n.settingsReceiveAlwaysBody,
              value: receiveAlways,
              onChanged: viewModel.setReceiveAlways,
            ),
          ],
          if (problem case final problem? when localSend && receiveAlways) ...[
            Spacing.v8,
            Text(
              switch (problem) {
                .cannotListen => l10n.receiveCannotListen,
                .noIdentity => l10n.receiveNoIdentity,
              },
              style: context.fluffyTheme.typography.caption1.copyWith(
                color: context.palette.warning,
              ),
            ),
            Spacing.v8,
            Align(
              alignment: .centerLeft,
              child: Button(
                mainAxisSize: .min,
                variant: .ghost,
                label: l10n.receiveTryAgain,
                onPressed: () => viewModel.setReceiveAlways(true),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
