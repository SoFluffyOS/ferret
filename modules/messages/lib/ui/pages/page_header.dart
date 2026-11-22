import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A page title with a back button when there is somewhere to go back to.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.backLabel,
    this.onBack,
  });

  final String title;
  final String backLabel;

  /// Null hides the back button.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        Spacing.d12,
        Spacing.d12,
        Spacing.d12,
        Spacing.d4,
      ),
      // Back takes a finger's taps out into the padding.
      child: OverhangHits(
        margin: EdgeInsetsDirectional.fromSTEB(
          Spacing.d12,
          Spacing.d12,
          Spacing.d12,
          Spacing.d4,
        ),
        child: Row(
          children: [
            if (onBack case final back?) ...[
              // Its glyph, not the room around it, lines up with the content.
              HeaderIconButton(
                icon: LucideIcons.chevronLeft,
                tooltip: backLabel,
                mirrors: true,
                padding: Spacing.d4,
                nudge: HeaderIconButton.backNudge,
                onTap: back,
              ),
              Spacing.h12,
            ],
            Expanded(
              child: Text(
                title,
                style: typography.title2.copyWith(color: palette.text),
                maxLines: 1,
                overflow: .ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
