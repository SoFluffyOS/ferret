import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class DropNobodyHint extends StatelessWidget {
  const DropNobodyHint({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final typography = context.fluffyTheme.typography;
    final palette = context.palette;

    return Column(
      mainAxisSize: .min,
      children: [
        Text(
          l10n.dropNobody,
          style: typography.base1.copyWith(
            color: palette.text,
            fontWeight: .w600,
          ),
          textAlign: .center,
        ),
        Spacing.vertical(Spacing.d2),
        Text(
          l10n.dropNobodyDetail,
          style: typography.caption1.copyWith(color: palette.mutedText),
          textAlign: .center,
        ),
      ],
    );
  }
}
