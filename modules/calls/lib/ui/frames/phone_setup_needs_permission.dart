import 'package:calls/l10n/l10n.dart';
import 'package:calls/ui/frames/open_settings_failed.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class PhoneSetupNeedsPermission extends StatelessWidget {
  const PhoneSetupNeedsPermission({super.key});

  @override
  Widget build(BuildContext context) {
    final stillOff = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.stillOff,
    );
    final needsSettings = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.needsSettings,
    );
    final viewModel = context.read<PhoneSetupViewModel>();
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;
    final status = switch (stillOff && needsSettings) {
      true => l10n.permissionStillOff,
      false => l10n.permissionOff,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          StatusLine(text: status, tone: .warning),
          Spacing.v4,
          Text(
            switch (needsSettings) {
              true => l10n.permissionHowToSettings,
              false => l10n.permissionHowTo,
            },
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
          const OpenSettingsFailed(),
          Spacing.v12,
          Button(
            variant: .primary,
            label: switch (needsSettings) {
              true => l10n.openSettings,
              false => l10n.allow,
            },
            onPressed: viewModel.allow,
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
