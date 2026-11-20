import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The small bar over another computer's display, while [shown]: it says
/// whose display this is, and has the ways out. Whoever holds it shows it
/// when the pointer reaches the top edge, so the rest of the time the
/// whole screen is that computer's.
class DisplayBar extends StatelessWidget {
  const DisplayBar({
    super.key,
    required this.shown,
    required this.onLeave,
    required this.title,
    required this.hint,
    required this.fullScreenLabel,
    required this.stopLabel,
    required this.onFullScreen,
    required this.onStop,
  });

  final bool shown;

  /// The pointer left the bar.
  final VoidCallback onLeave;

  final String title;

  /// How to leave full screen without the bar.
  final String hint;
  final String fullScreenLabel;
  final String stopLabel;
  final VoidCallback onFullScreen;
  final VoidCallback onStop;

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
          padding: EdgeInsets.only(top: Spacing.d8),
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
                              maxLines: 1,
                              overflow: .ellipsis,
                              style: typography.caption1.copyWith(
                                color: palette.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacing.h16,
                      Button(
                        variant: .ghost,
                        mainAxisSize: .min,
                        label: fullScreenLabel,
                        onPressed: onFullScreen,
                      ),
                      Spacing.h4,
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
