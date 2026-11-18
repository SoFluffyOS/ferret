import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One line of a window's device list: a device, one of its sections, or a
/// place such as Activity. The selected line is filled, so it is always
/// clear what the pane next to it shows.
class SidebarRow extends StatelessWidget {
  const SidebarRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.trailing,
    this.isSelected = false,
    this.isDimmed = false,
    this.isIndented = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  /// At the end of the line, such as a count or a status dot.
  final Widget? trailing;
  final bool isSelected;

  /// For something that is there and not set up yet.
  final bool isDimmed;

  /// A level below the line above, such as a device's section.
  final bool isIndented;
  final String? tooltip;

  /// Lines are a finger high on touch screens, and denser under a pointer.
  static double get height => switch (defaultTargetPlatform) {
    .android || .iOS || .fuchsia => Spacing.d44,
    .macOS || .windows || .linux => Spacing.d32,
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // The grey of a dimmed line is too faint on the selected line's fill.
    final textColor = switch ((isDimmed, isSelected)) {
      (true, false) => palette.mutedText,
      _ => palette.text,
    };

    // The line's text is its name; the tooltip only adds to it, so it
    // must not become the label.
    return Semantics(
      selected: isSelected,
      child: Tappable(
        onTap: onTap,
        tooltip: tooltip,
        semanticLabel: '',
        semanticButton: onTap != null,
        enableAnimation: false,
        enableHover: true,
        // The line draws its own ring, inside its rounded fill.
        enableFocusBorder: false,
        builder: (context, state) => Container(
          // At least a line high, and taller when text is set large:
          // a fixed height would cut the letters.
          constraints: BoxConstraints(minHeight: height),
          margin: EdgeInsets.symmetric(
            horizontal: Spacing.d8,
            vertical: Spacing.d1,
          ),
          padding: EdgeInsets.only(
            left: switch (isIndented) {
              true => Spacing.d32,
              false => Spacing.d8,
            },
            right: Spacing.d8,
          ),
          decoration: BoxDecoration(
            color: _fill(palette, state),
            borderRadius: BorderRadius.circular(Spacing.d8),
            border: Border.all(
              color: switch (state) {
                .focus => palette.accent,
                _ => const Color(0x00000000),
              },
              width: Spacing.d2,
            ),
          ),
          child: Row(
            children: [
              if (icon case final icon?) ...[
                Icon(icon, size: Spacing.d16, color: textColor),
                Spacing.h8,
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: context.fluffyTheme.typography.base2.copyWith(
                    color: textColor,
                  ),
                ),
              ),
              if (trailing case final trailing?) ...[Spacing.h8, trailing],
            ],
          ),
        ),
      ),
    );
  }

  Color? _fill(FerretPalette palette, TappableState state) {
    if (isSelected) {
      return palette.accent.withValues(alpha: 0.18);
    }

    return switch (state) {
      .hover || .pressed => palette.text.withValues(alpha: 0.06),
      .normal || .focus => null,
    };
  }
}
