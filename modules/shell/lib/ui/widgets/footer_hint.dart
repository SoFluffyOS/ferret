import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The one muted line at the bottom of Home, with at most one thing to
/// tap, such as "Paused until 14:00 · Resume".
class FooterHint extends StatelessWidget {
  const FooterHint({
    super.key,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = context.fluffyTheme.typography.caption1;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        Spacing.d16,
        Spacing.d8,
        Spacing.d16,
        Spacing.d12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: .ellipsis,
              style: style.copyWith(color: palette.mutedText),
            ),
          ),
          if (actionLabel case final label?)
            Tappable(
              onTap: onAction,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Spacing.d4),
                child: Text(
                  label,
                  style: style.copyWith(color: palette.link),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
