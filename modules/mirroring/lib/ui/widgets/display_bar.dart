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
  });

  final bool shown;

  /// The pointer left the bar.
  final VoidCallback onLeave;

  final String title;

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
                  shape: Corners.shape(Corners.card),
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
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisSize: .min,
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: .ellipsis,
                              style: typography.base2.copyWith(
                                color: palette.text,
                                fontWeight: .w600,
                              ),
                            ),
                            Text(
                              hint,
                              maxLines: 2,
                              overflow: .ellipsis,
                              style: typography.caption1.copyWith(
                                color: palette.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacing.h16,
                      if (fullScreenLabel case final label?) ...[
                        Button(
                          variant: .ghost,
                          mainAxisSize: .min,
                          label: label,
                          onPressed: onFullScreen,
                        ),
                        Spacing.h4,
                      ],
                      Button(
                        variant: .ghost,
                        mainAxisSize: .min,
                        label: stopLabel,
                        onPressed: onStop,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
