import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:notifications/l10n/l10n.dart';
import 'package:notifications/ui/widgets/widgets.dart';
import 'package:notifications/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card on the phone: an invitation to set mirroring up, a fix when
/// access is off, or a quiet status line.
class PhoneHomeFrame extends StatelessWidget {
  const PhoneHomeFrame({super.key, required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final stage = context.select<MirrorSetupViewModel, SetupStage>(
      (viewModel) => viewModel.stage,
    );
    final checked = context.select<MirrorSetupViewModel, bool>(
      (viewModel) => viewModel.checked,
    );
    final appCount = context.select<MirrorSetupViewModel, int>(
      (viewModel) => viewModel.allowedAppCount,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.notificationsL10n;

    final Widget body = switch (stage) {
      .off => Row(
        children: [
          Expanded(
            child: Text(
              l10n.explainer,
              style: typography.body2.copyWith(color: palette.mutedText),
            ),
          ),
          Spacing.h12,
          Button(variant: .secondary, label: l10n.setUp, onPressed: onSetUp),
        ],
      ),
      .needsAccess when checked => Row(
        children: [
          Expanded(
            child: StatusLine(text: l10n.phoneHomePaused, tone: .warning),
          ),
          Spacing.h12,
          Button(variant: .secondary, label: l10n.fix, onPressed: onSetUp),
        ],
      ),
      .needsAccess => const SizedBox.shrink(),
      .ready => StatusLine(text: l10n.phoneHomeOn(appCount), tone: .good),
    };

    return SurfaceCard(
      onTap: onSetUp,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bell, size: Spacing.d16, color: palette.text),
              Spacing.h8,
              Expanded(
                child: Text(
                  l10n.title,
                  style: typography.base1.copyWith(color: palette.text),
                ),
              ),
            ],
          ),
          Spacing.v8,
          body,
        ],
      ),
    );
  }
}
