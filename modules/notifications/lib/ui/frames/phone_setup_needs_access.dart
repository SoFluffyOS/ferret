import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class PhoneSetupNeedsAccess extends StatelessWidget {
  const PhoneSetupNeedsAccess({super.key});

  @override
  Widget build(BuildContext context) {
    final stillOff = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.stillOff,
    );
    final restricted = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.restricted,
    );
    final openFailed = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.openFailed,
    );
    final viewModel = context.read<MirrorSetupViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;
    final status = switch (stillOff) {
      true => l10n.accessStillOff,
      false => l10n.accessOff,
    };

    return GroupedCard(
      children: [
        GroupedCell(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              StatusLine(text: status, tone: .warning),
              Spacing.v4,
              Text(
                l10n.accessHowTo,
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
              if (openFailed) ...[
                Spacing.v8,
                Text(
                  l10n.openSettingsFailed,
                  style: typography.caption1.copyWith(color: palette.danger),
                ),
              ],
              Spacing.v12,
              Button(
                variant: .primary,
                label: l10n.openAccessShort,
                tooltip: l10n.openAccessSettings,
                semanticLabel: l10n.openAccessSettings,
                onPressed: viewModel.openAccessSettings,
              ),
            ],
          ),
        ),
        if (restricted)
          GroupedCell(
            child: RestrictedGuide(onOpenAppInfo: viewModel.openAppInfo),
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
