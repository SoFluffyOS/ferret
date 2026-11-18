import 'package:calls/l10n/l10n.dart';
import 'package:calls/ui/widgets/widgets.dart';
import 'package:calls/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The home card on the phone: an invitation to set calls up, or a fix when
/// the permission is missing. Once calls work it shows nothing.
class PhoneHomeFrame extends StatelessWidget {
  const PhoneHomeFrame({super.key, required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final stage = context.select<PhoneSetupViewModel, CallsSetupStage>(
      (viewModel) => viewModel.stage,
    );
    final checked = context.select<PhoneSetupViewModel, bool>(
      (viewModel) => viewModel.checked,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.callsL10n;

    if (stage == .ready || (stage == .needsPermission && !checked)) {
      return const SizedBox.shrink();
    }

    final Widget status = switch (stage) {
      .off => Text(
        l10n.explainer,
        style: typography.body2.copyWith(color: palette.mutedText),
      ),
      _ => StatusLine(text: l10n.phoneHomePaused, tone: .warning),
    };

    return SurfaceCard(
      onTap: onSetUp,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.phone, size: Spacing.d16, color: palette.text),
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
          Row(
            children: [
              Expanded(child: status),
              Spacing.h12,
              Button(
                variant: .secondary,
                label: switch (stage) {
                  .off => l10n.setUp,
                  _ => l10n.fix,
                },
                onPressed: onSetUp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
