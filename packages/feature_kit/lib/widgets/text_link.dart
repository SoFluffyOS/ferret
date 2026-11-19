import 'package:feature_kit/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A few words to press, drawn as a link: "See all", "Cancel", "What's
/// new". The words stay small; what takes the pointer is at least
/// [minHeight] high, so it can be hit without aiming.
class TextLink extends StatelessWidget {
  const TextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.style,
    this.alignment = Alignment.center,
  });

  final String label;
  final VoidCallback? onTap;

  /// Caption-sized when left out. The link colour is applied on top.
  final TextStyle? style;

  /// Where the words sit in what takes the pointer. At the top, the link
  /// lines up with words next to it and its target reaches down into the
  /// space below, so a row of text doesn't grow for it.
  final AlignmentGeometry alignment;

  /// The least a pointer target should be (WCAG 2.2, 2.5.8).
  static double get minHeight => Spacing.d24;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? context.fluffyTheme.typography.caption1;

    return Tappable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.d4),
          child: Align(
            alignment: alignment,
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: style.copyWith(color: context.palette.link),
            ),
          ),
        ),
      ),
    );
  }
}
