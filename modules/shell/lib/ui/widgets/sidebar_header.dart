import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/ui/widgets/sidebar_row.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A heading in a window's device list, such as "Your devices". It can
/// hold the one thing to do with what is under it, and fold it away.
class SidebarHeader extends StatelessWidget {
  const SidebarHeader({
    super.key,
    required this.title,
    this.action,
    this.isCollapsed,
    this.onToggle,
  });

  final String title;

  /// At the end of the heading, such as the + that adds a device.
  final Widget? action;

  /// Whether what is under the heading is folded away. Null for a
  /// heading that doesn't fold.
  final bool? isCollapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = context.fluffyTheme.typography.caption1.copyWith(
      color: palette.mutedText,
      fontWeight: .w600,
    );
    final isCollapsed = this.isCollapsed;
    final label = Padding(
      // Tall enough to press: 24 with the line of text.
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: Row(
        mainAxisSize: .min,
        children: [
          Flexible(
            child: Text(
              title,
              style: style,
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ),
          if (isCollapsed != null) ...[
            Spacing.h4,
            Icon(
              switch (isCollapsed) {
                true => LucideIcons.chevronRight,
                false => LucideIcons.chevronDown,
              },
              size: Spacing.d12,
              color: palette.mutedText,
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SidebarRow.margin + SidebarRow.inset,
        Spacing.d8,
        SidebarRow.margin,
        Spacing.d2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: .centerLeft,
              child: switch (isCollapsed) {
                null => label,
                final isCollapsed => Semantics(
                  expanded: !isCollapsed,
                  child: Tappable(
                    semanticLabel: '',
                    semanticButton: true,
                    enableAnimation: false,
                    hoverOverlayBorderRadius: Corners.tile,
                    onTap: onToggle,
                    child: label,
                  ),
                ),
              },
            ),
          ),
          // A stop of its own for a screen reader, not part of the heading.
          if (action case final action?)
            Semantics(container: true, child: action),
        ],
      ),
    );
  }
}
