import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/ui/widgets/widgets.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class PhoneSetupNeedsAccess extends StatelessWidget {
  const PhoneSetupNeedsAccess({super.key});

  @override
  Widget build(BuildContext context) {
    final stillOff = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.stillOff,
    );
    final blocked = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.blocked,
    );
    final openFailed = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.openFailed,
    );
    final asking = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.asking,
    );
    final viewModel = context.read<PhoneSetupViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;
    final status = switch (stillOff) {
      true => l10n.accessStillOff,
      false => l10n.accessOff,
    };
    final howTo = switch (blocked) {
      true => l10n.accessBlocked,
      false => l10n.accessHowTo,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          StatusLine(text: status, tone: .warning),
          Spacing.v4,
          Text(
            howTo,
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
            label: switch (blocked) {
              true => l10n.openAppSettings,
              false => l10n.allowAccess,
            },
            enable: !asking,
            onPressed: viewModel.requestAccess,
          ),
          Spacing.v8,
          Button(
            variant: .ghost,
            label: l10n.turnOff,
            onPressed: viewModel.turnOff,
          ),
        ],
      ),
    );
  }
}
