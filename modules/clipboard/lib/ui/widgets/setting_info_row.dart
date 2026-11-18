import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A setting that can't be switched yet: its title, a lock, and the line
/// that says what it needs.
class SettingInfoRow extends StatelessWidget {
  const SettingInfoRow({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: typography.base1.copyWith(color: palette.mutedText),
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
          Spacing.h12,
          Icon(LucideIcons.lock, size: Spacing.d16, color: palette.mutedText),
        ],
      ),
    );
  }
}
