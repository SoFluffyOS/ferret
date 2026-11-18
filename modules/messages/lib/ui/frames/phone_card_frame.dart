import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The phone's home card: whether its texts are shared, with Set up.
class PhoneCardFrame extends StatelessWidget {
  const PhoneCardFrame({super.key, required this.onSetUp});

  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final stage = context.select<PhoneSetupViewModel, SetupStage>(
      (viewModel) => viewModel.stage,
    );
    if (stage == .unsupported) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;
    final subtitle = switch (stage) {
      .ready => l10n.phoneCardOn,
      .needsAccess => l10n.phoneCardNeedsAccess,
      _ => l10n.phoneCardOff,
    };

    return SurfaceCard(
      onTap: onSetUp,
      child: Row(
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: Spacing.d20,
            color: palette.text,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  l10n.title,
                  style: typography.base1.copyWith(color: palette.text),
                ),
                Spacing.vertical(Spacing.d2),
                Text(
                  subtitle,
                  style: typography.caption1.copyWith(
                    color: switch (stage) {
                      .needsAccess => palette.danger,
                      _ => palette.mutedText,
                    },
                  ),
                ),
              ],
            ),
          ),
          if (stage != .ready)
            Button(variant: .secondary, label: l10n.setUp, onPressed: onSetUp),
        ],
      ),
    );
  }
}
