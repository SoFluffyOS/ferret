import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:find/l10n/l10n.dart';
import 'package:find/models/models.dart';
import 'package:find/ui/widgets/widgets.dart';
import 'package:find/view_models/view_models.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The ringing screen on this device: who is looking for it, and a big
/// "Found it" at the bottom.
class RingingFrame extends StatelessWidget {
  const RingingFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final ring = context.select<FindViewModel, LocalRing>(
      (viewModel) => viewModel.localRing,
    );
    final l10n = context.findL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: .min,
                children: [
                  Icon(
                    LucideIcons.bellRing,
                    size: Spacing.d96,
                    color: palette.accent,
                  ),
                  Spacing.v24,
                  Text(
                    l10n.ringingTitle,
                    textAlign: .center,
                    style: typography.title1.copyWith(color: palette.text),
                  ),
                  Spacing.v8,
                  Text(
                    l10n.ringingBody(ring.requesterName),
                    textAlign: .center,
                    style: typography.body1.copyWith(color: palette.mutedText),
                  ),
                  if (ring.muted) ...[
                    Spacing.v8,
                    Text(
                      l10n.ringingMuted,
                      textAlign: .center,
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        FoundItButton(
          large: true,
          onPressed: () => unawaited(context.read<FindViewModel>().foundIt()),
        ),
      ],
    );
  }
}
