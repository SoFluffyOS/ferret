import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One line above a page that shows what was loaded last, because its
/// device is offline: says so, since when, and offers the way to fix it.
class OfflineLine extends StatelessWidget {
  const OfflineLine({
    super.key,
    required this.text,
    required this.fixLabel,
    required this.onFix,
  });

  final String text;
  final String fixLabel;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.d12,
        vertical: Spacing.d8,
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.wifiOff,
            size: Spacing.d16,
            color: palette.mutedText,
          ),
          Spacing.h8,
          Expanded(
            child: Text(
              text,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ),
          Spacing.h8,
          Tappable(
            onTap: onFix,
            child: Padding(
              padding: EdgeInsets.all(Spacing.d4),
              child: Text(
                fixLabel,
                style: typography.base2.copyWith(color: palette.link),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
