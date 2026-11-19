import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A setting that can't be switched yet: its title, a lock, and the line
/// that says what it needs. Without [showLock], a plain explanation. A row
/// of a `GroupedCard`, with the geometry of a `GroupedRow`.
class SettingInfoRow extends StatelessWidget {
  const SettingInfoRow({
    super.key,
    required this.title,
    required this.body,
    this.showLock = true,
  });

  final String title;
  final String body;
  final bool showLock;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final titleStyle = GroupedRow.titleStyleOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: GroupedRow.minHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: PageInsets.row,
          vertical: Spacing.d8,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(
                    title,
                    style: titleStyle.copyWith(color: palette.mutedText),
                  ),
                  Spacing.vertical(Spacing.d2),
                  Text(
                    body,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (showLock) ...[
              Spacing.h12,
              Icon(
                LucideIcons.lock,
                size: Spacing.d16,
                color: palette.mutedText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
