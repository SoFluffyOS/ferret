import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/handoff.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Continue “title” from Pixel" with Open and a quiet dismiss.
class SuggestionTile extends StatelessWidget {
  const SuggestionTile({
    super.key,
    required this.suggestion,
    required this.onOpen,
    required this.onDismiss,
  });

  final Suggestion suggestion;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.handoffL10n;
    final activity = suggestion.activity;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d4),
      child: Row(
        children: [
          Icon(
            iconFor(activity.kind),
            size: Spacing.d20,
            color: palette.mutedText,
          ),
          Spacing.h12,
          Expanded(
            child: Text(
              l10n.continueFrom(activity.title, suggestion.from.name),
              style: typography.body2.copyWith(color: palette.text),
              maxLines: 2,
              overflow: .ellipsis,
            ),
          ),
          Spacing.h8,
          Button(
            variant: .secondary,
            label: l10n.open,
            mainAxisSize: .min,
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.d12,
              vertical: Spacing.d6,
            ),
            onPressed: onOpen,
          ),
          Spacing.h4,
          Tappable(
            tooltip: l10n.dismiss,
            onTap: onDismiss,
            child: Padding(
              padding: EdgeInsets.all(Spacing.d6),
              child: Icon(
                LucideIcons.x,
                size: Spacing.d16,
                color: palette.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData iconFor(ActivityKind kind) => switch (kind) {
    .ACTIVITY_KIND_APP => LucideIcons.appWindow,
    .ACTIVITY_KIND_GEO => LucideIcons.mapPin,
    .ACTIVITY_KIND_TEXT => LucideIcons.text,
    _ => LucideIcons.globe,
  };
}
