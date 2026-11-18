import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What the list of devices near you says when it is empty: still looking,
/// nothing found, or not allowed to look, with the one thing to do about it.
class NearbyNotice extends StatelessWidget {
  const NearbyNotice({
    super.key,
    required this.body,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return SurfaceCard(
      padding: EdgeInsets.all(Spacing.d16),
      child: Column(
        children: [
          if (title case final title?) ...[
            Text(
              title,
              textAlign: .center,
              style: typography.base1.copyWith(color: palette.text),
            ),
            Spacing.v4,
          ],
          Text(
            body,
            textAlign: .center,
            style: typography.base2.copyWith(color: palette.mutedText),
          ),
          if (actionLabel case final label?) ...[
            Spacing.v12,
            Button(
              mainAxisSize: .min,
              variant: .ghost,
              label: label,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
