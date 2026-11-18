import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One line over the picture that says something once: what it is, a
/// link for what to do about it, and a way to send it off.
class StageNoticeBar extends StatelessWidget {
  const StageNoticeBar({
    super.key,
    required this.text,
    required this.dismissLabel,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String dismissLabel;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(Spacing.d12),
        boxShadow: [
          BoxShadow(
            color: palette.text.withValues(alpha: 0.18),
            blurRadius: Spacing.d16,
            offset: Offset(0, Spacing.d4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Spacing.d12,
          Spacing.d6,
          Spacing.d6,
          Spacing.d6,
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            Flexible(
              child: Text(
                text,
                style: typography.caption1.copyWith(color: palette.text),
              ),
            ),
            if ((actionLabel, onAction) case (final label?, final action?)) ...[
              Spacing.h8,
              Tappable(
                onTap: action,
                child: Padding(
                  padding: EdgeInsets.all(Spacing.d4),
                  child: Text(
                    label,
                    style: typography.caption1.copyWith(color: palette.accent),
                  ),
                ),
              ),
            ],
            Spacing.h4,
            Tappable(
              tooltip: dismissLabel,
              onTap: onDismiss,
              child: Padding(
                padding: EdgeInsets.all(Spacing.d4),
                child: Icon(
                  LucideIcons.x,
                  size: Spacing.d14,
                  color: palette.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
