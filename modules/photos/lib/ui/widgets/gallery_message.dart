import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What a Photos page says instead of a grid: why there is nothing to see,
/// and the one thing to do about it.
class GalleryMessage extends StatelessWidget {
  const GalleryMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.note,
  });

  final IconData icon;
  final String title;
  final String? body;

  /// The fix, such as "Ask on Pixel 7": the page's one primary button.
  final Widget? action;

  /// A quiet line under the action, such as that the question was sent.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.d40),
      child: Column(
        mainAxisSize: .min,
        children: [
          Icon(icon, size: Spacing.d32, color: palette.mutedText),
          Spacing.v12,
          Text(
            title,
            textAlign: .center,
            style: typography.base1.copyWith(color: palette.text),
          ),
          if (body case final body?) ...[
            Spacing.v8,
            Text(
              body,
              textAlign: .center,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ],
          if (action case final action?) ...[Spacing.v16, action],
          if (note case final note?) ...[
            Spacing.v8,
            Text(
              note,
              textAlign: .center,
              style: typography.base2.copyWith(color: palette.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}
