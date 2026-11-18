import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The promise, in one quiet line: no account, no cloud, stays on your
/// network.
class PrivacyLine extends StatelessWidget {
  const PrivacyLine({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      mainAxisAlignment: .center,
      children: [
        Icon(LucideIcons.lock, size: Spacing.d12, color: palette.mutedText),
        Spacing.h6,
        Flexible(
          child: Text(
            context.shellL10n.welcomePrivacy,
            style: context.fluffyTheme.typography.caption1.copyWith(
              color: palette.mutedText,
            ),
          ),
        ),
      ],
    );
  }
}
