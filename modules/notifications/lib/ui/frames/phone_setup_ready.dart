import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:protocol/notifications.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class PhoneSetupReady extends StatelessWidget {
  const PhoneSetupReady({super.key, required this.onChooseApps});

  final VoidCallback onChooseApps;

  @override
  Widget build(BuildContext context) {
    final skipWhileUsing = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.skipWhileUsing,
    );
    final hideCodes = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.hideCodes,
    );
    final appFilter = context.select<MirrorSetupViewModel, AppFilter>(
      (viewModel) => viewModel.appFilter,
    );
    final appCount = context.select<MirrorSetupViewModel, int>(
      (viewModel) => viewModel.namedAppCount,
    );
    final viewModel = context.read<MirrorSetupViewModel>();
    final l10n = context.notificationsL10n;

    return GroupedCard(
      children: [
        GroupedCell(
          child: StatusLine(text: l10n.accessOn, tone: .good),
        ),
        SettingSwitchRow(
          title: l10n.skipWhileUsing,
          body: l10n.skipWhileUsingDetail,
          value: skipWhileUsing,
          onChanged: viewModel.setSkipWhileUsing,
        ),
        SettingSwitchRow(
          title: l10n.hideCodes,
          body: l10n.hideCodesDetail(ThisComputer.handheld),
          value: hideCodes,
          onChanged: viewModel.setHideCodes,
        ),
        GroupedCell(
          child: Button(
            variant: .ghost,
            label: l10n.chooseApps,
            tooltip:
                '${l10n.chooseApps} · ${l10n.appsSummary(appFilter, appCount)}',
            semanticLabel:
                '${l10n.chooseApps} · ${l10n.appsSummary(appFilter, appCount)}',
            onPressed: onChooseApps,
          ),
        ),
        GroupedCell(
          child: Button(
            variant: .ghost,
            label: l10n.turnOff,
            onPressed: viewModel.turnOff,
          ),
        ),
      ],
    );
  }
}
