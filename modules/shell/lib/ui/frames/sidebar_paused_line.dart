import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Shown only while Ferret is paused, with the way out next to it.
class SidebarPausedLine extends StatelessWidget {
  const SidebarPausedLine({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    // The link's target is the line's height.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.d16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.homeStatusPaused,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ),
          TextLink(
            label: l10n.resume,
            onTap: () => unawaited(context.read<PauseController>().resume()),
            style: typography.base2,
          ),
        ],
      ),
    );
  }
}
