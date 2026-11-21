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
    this.dropLabel,
    this.dropRefused = false,
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

  /// While something is dragged over the line: what a drop does, such as
  /// "Drop to send to Pixel 7", shown over the line without moving it.
  final String? dropLabel;

  /// The line can't take what is dragged over it: [dropLabel] says why,
  /// in grey.
  final bool dropRefused;
  final String? tooltip;

  /// Lines are a finger high on touch screens, and denser under a pointer.
  static double get height => switch (defaultTargetPlatform) {
    .android || .iOS || .fuchsia => Spacing.d44,
    .macOS || .windows || .linux => Spacing.d32,
  };

  /// Between the list's edge and a line's fill.
  static double get margin => Spacing.d8;

  /// Between a line's fill and what is in it. Headings in the list start
  /// at [margin] plus this, where the lines' icons do.
  static double get inset => Spacing.d8;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textScaler = MediaQuery.textScalerOf(context);
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
        // The line draws its own ring, on the shape of its fill.
        enableFocusBorder: false,
        builder: (context, state) => Padding(
          padding: EdgeInsets.symmetric(
            horizontal: margin,
            vertical: Spacing.d1,
          ),
          child: DropOverlay(
            radius: Corners.row,
            label: dropLabel,
            refused: dropRefused,
            compact: true,
            child: Container(
              // At least a line high, and taller when text is set large:
              // a fixed height would cut the letters.
              constraints: BoxConstraints(minHeight: height),
              padding: EdgeInsetsDirectional.only(
                start: switch (isIndented) {
                  true => Spacing.d32,
                  false => inset,
                },
                end: inset,
              ),
              decoration: ShapeDecoration(
                color: _fill(palette, state),
                shape: Corners.shape(
                  Corners.row,
                  side: BorderSide(
                    color: switch (state) {
                      .focus => palette.accent,
                      _ => const Color(0x00000000),
                    },
                    width: Spacing.d2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (icon case final icon?) ...[
                    Icon(
                      icon,
                      size: textScaler
                          .clamp(maxScaleFactor: 2)
                          .scale(Spacing.d16),
                      color: textColor,
                    ),
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
