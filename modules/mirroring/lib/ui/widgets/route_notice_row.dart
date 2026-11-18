import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One step a way to show a screen still needs: what, in a headline, and
/// how to do it underneath, then what went wrong and a button, when there
/// are some.
class RouteNoticeRow extends StatelessWidget {
  const RouteNoticeRow({
    super.key,
    required this.title,
    required this.body,
    this.error,
    this.action,
  });

  final String title;
  final String body;
  final String? error;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d6),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: Spacing.d2),
            child: Icon(
              LucideIcons.wrench,
              size: Spacing.d16,
              color: palette.warning,
            ),
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  style: typography.base1.copyWith(color: palette.text),
                ),
                Spacing.vertical(Spacing.d2),
                Text(
                  body,
                  style: typography.caption1.copyWith(
                    color: palette.mutedText,
                  ),
                ),
                if (error case final message?) ...[
                  Spacing.vertical(Spacing.d4),
                  Text(
                    message,
                    style: typography.caption1.copyWith(color: palette.danger),
                  ),
                ],
                if (action case final button?) ...[Spacing.v8, button],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
