import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:power/l10n/l10n.dart';
import 'package:power/models/models.dart';
import 'package:power/ui/widgets/widgets.dart';
import 'package:power/view_models/power_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Root: whether the phone has it, a plain warning, and the one button that
/// makes Ferret ask for it.
class PowerRootFrame extends StatelessWidget {
  const PowerRootFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final root = context.select<PowerViewModel, RootStatus>(
      (viewModel) => viewModel.status.root,
    );
    final manager = context.select<PowerViewModel, RootManager>(
      (viewModel) => viewModel.status.rootManager,
    );
    final usesRoot = context.select<PowerViewModel, bool>(
      (viewModel) => viewModel.usesRoot,
    );
    final isBusy = context.select<PowerViewModel, bool>(
      (viewModel) => viewModel.isBusy,
    );
    final notice = context.select<PowerViewModel, PowerNotice?>(
      (viewModel) => viewModel.notice,
    );
    final viewModel = context.read<PowerViewModel>();
    final l10n = context.powerL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    if (root == .notFound) {
      return SurfaceCard(
        child: Text(
          l10n.rootNotFound,
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
      );
    }

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            l10n.rootFoundText(manager),
            style: typography.base1.copyWith(color: palette.text),
          ),
          Spacing.v8,
          Row(
            crossAxisAlignment: .start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: Spacing.d2),
                child: Icon(
                  LucideIcons.triangleAlert,
                  size: Spacing.d16,
                  color: palette.warning,
                ),
              ),
              Spacing.h8,
              Expanded(
                child: Text(
                  l10n.rootWarning,
                  style: typography.caption1.copyWith(color: palette.warning),
                ),
              ),
            ],
          ),
          if (usesRoot) NoticeText(l10n.rootOn, tone: .success),
          if (!usesRoot) NoticeText(l10n.rootPromptHint),
          if (notice == .rootRefused)
            NoticeText(l10n.noticeRootRefused, tone: .danger),
          Spacing.v8,
          Align(
            alignment: .centerLeft,
            child: switch (usesRoot) {
              true => Button(
                mainAxisSize: .min,
                variant: .ghost,
                label: l10n.stopUsingRoot,
                enable: !isBusy,
                onPressed: viewModel.stopUsingRoot,
              ),
              false => Button(
                mainAxisSize: .min,
                variant: .ghost,
                label: l10n.useRoot,
                enable: !isBusy,
                onPressed: viewModel.useRoot,
              ),
            },
          ),
        ],
      ),
    );
  }
}
