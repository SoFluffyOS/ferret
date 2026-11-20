import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One line of a toolbar popup: an icon, a name, a quieter word after it,
/// and a tick when it is the one chosen.
class PopupRow extends StatelessWidget {
  const PopupRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.detail,
    this.checked,
    this.badge,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? detail;

  /// Null for a row that isn't a choice.
  final bool? checked;

  /// A small widget after [label], such as a `BetaTag`.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final leading = switch (checked) {
      true => LucideIcons.check,
      false => null,
      null => icon,
    };

    return Tappable(
      onTap: onTap,
      enableHover: true,
      enableHoverOverlay: true,
      // Inset from the popup's sides as far as from its top, and concentric
      // with its corner, like a menu's highlight.
      hoverOverlayPadding: EdgeInsets.symmetric(horizontal: Spacing.d6),
      hoverOverlayBorderRadius: Corners.inner(Corners.card, Spacing.d6),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.d12,
          vertical: Spacing.d8,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: Spacing.d16,
              child: switch (leading) {
                final shown? => Icon(
                  shown,
                  size: Spacing.d16,
                  color: palette.mutedText,
                ),
                null => null,
              },
            ),
            Spacing.h8,
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: .ellipsis,
                      style: typography.base2.copyWith(color: palette.text),
                    ),
                  ),
                  if (badge case final badge?) ...[Spacing.h8, badge],
                ],
              ),
            ),
            if (detail case final detail?) ...[
              Spacing.h12,
              Text(
                detail,
                style: typography.caption1.copyWith(color: palette.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
