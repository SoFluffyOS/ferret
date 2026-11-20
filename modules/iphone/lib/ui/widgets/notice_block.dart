import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A problem or a limit in plain words, with an optional fix button.
class NoticeBlock extends StatelessWidget {
  const NoticeBlock({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.isProblem = true,
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A problem shows a warning icon; a limit shows an info icon.
  final bool isProblem;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final (icon, color) = switch (isProblem) {
      true => (LucideIcons.triangleAlert, palette.warning),
      false => (LucideIcons.info, palette.mutedText),
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            Icon(icon, size: Spacing.d16, color: color),
            Spacing.h8,
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    title,
                    style: typography.body2.copyWith(color: palette.text),
                  ),
                  if (body case final body?) ...[
                    Spacing.vertical(Spacing.d2),
                    Text(
                      body,
                      style: typography.caption1.copyWith(
                        color: palette.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if ((actionLabel, onAction) case (final label?, final action?)) ...[
          Spacing.v8,
          GhostButton(label: label, onPressed: action),
        ],
      ],
    );
  }
}
