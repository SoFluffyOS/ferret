import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The small bar over another computer's display, while [shown]: it says
/// whose display this is, and has the ways out. Whoever holds it shows it
/// when the pointer reaches the top edge, or the handle there is tapped on
/// a phone, so the rest of the time the whole screen is that computer's.
class DisplayBar extends StatelessWidget {
  const DisplayBar({
    super.key,
    required this.shown,
    required this.onLeave,
    required this.title,
    required this.hint,
    required this.stopLabel,
    required this.onStop,
    this.fullScreenLabel,
    this.onFullScreen,
    this.badge,
  });

  final bool shown;

  /// The pointer left the bar.
  final VoidCallback onLeave;

  final String title;

  /// A small widget after [title], such as a `BetaTag`.
  final Widget? badge;

  /// How to leave full screen without the bar.
  final String hint;
  final String stopLabel;
  final VoidCallback onStop;

  /// Null where the display always fills the screen, as on a phone.
  final String? fullScreenLabel;
  final VoidCallback? onFullScreen;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    // At large text the words take the bar's whole width and wrap, and
    // the buttons go under them.
    final largeText = context.hasLargeText;
    final words = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Row(
          mainAxisSize: .min,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: switch (largeText) {
                  true => 2,
                  false => 1,
                },
                overflow: .ellipsis,
                style: typography.base2.copyWith(
                  color: palette.text,
                  fontWeight: .w600,
                ),
              ),
            ),
            if (badge case final badge?) ...[Spacing.h8, badge],
          ],
        ),
        Text(
          hint,
          maxLines: switch (largeText) {
            true => null,
            false => 2,
          },
          // Ellipsis would cut a text with no line limit to one line.
          overflow: switch (largeText) {
            true => .clip,
            false => .ellipsis,
          },
          style: typography.caption1.copyWith(color: palette.mutedText),
        ),
      ],
    );
    final buttons = [
      if (fullScreenLabel case final label?) ...[
        GhostButton(
          mainAxisSize: .min,
          radius: Corners.control,
          label: label,
          onPressed: onFullScreen,
        ),
        Spacing.h4,
      ],
      GhostButton(
        mainAxisSize: .min,
        radius: Corners.control,
        label: stopLabel,
        onPressed: onStop,
      ),
    ];

    return AnimatedOpacity(
      opacity: switch (shown) {
        true => 1,
        false => 0,
      },
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(
        ignoring: !shown,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Spacing.d16,
            Spacing.d8,
            Spacing.d16,
            0,
          ),
          child: Center(
            child: MouseRegion(
              onExit: (_) => onLeave(),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: palette.surface,
                  // The bar wraps its buttons' corners, 8 out.
                  shape: Corners.shape(
                    Corners.around(Corners.control, Spacing.d8),
                  ),
                  shadows: [
                    BoxShadow(
                      color: palette.text.withValues(alpha: 0.18),
                      blurRadius: Spacing.d16,
                      offset: Offset(0, Spacing.d4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    Spacing.d16,
                    Spacing.d8,
                    Spacing.d8,
                    Spacing.d8,
                  ),
                  child: switch (largeText) {
                    true => Column(
                      mainAxisSize: .min,
                      crossAxisAlignment: .stretch,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(end: Spacing.d8),
                          child: words,
                        ),
                        Spacing.v8,
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Row(mainAxisSize: .min, children: buttons),
                        ),
                      ],
                    ),
                    false => Row(
                      mainAxisSize: .min,
                      children: [
                        Flexible(child: words),
                        Spacing.h16,
                        ...buttons,
                      ],
                    ),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
