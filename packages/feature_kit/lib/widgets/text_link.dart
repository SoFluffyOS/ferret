import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/outset_touch_target.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A few words to press, drawn as a link: "See all", "Cancel", "What's
/// new". The words stay small; what takes a pointer is at least
/// [minHeight] high, so it can be hit without aiming. A finger gets the
/// density's 48 dp around it, reaching past the line without growing it.
class TextLink extends StatelessWidget {
  const TextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.style,
    this.alignment = Alignment.center,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;

  /// Caption-sized when left out. The link colour is applied on top.
  final TextStyle? style;

  /// Where the words sit in what takes the pointer. At the top, the link
  /// lines up with words next to it and its target reaches down into the
  /// space below, so a row of text doesn't grow for it.
  final AlignmentGeometry alignment;

  /// What a screen reader says instead of [label], when several links on
  /// a screen share the same words.
  final String? semanticLabel;

  /// The least a pointer target should be (WCAG 2.2, 2.5.8), and how high
  /// the link lays out with a finger too.
  static double get minHeight => Spacing.d24;

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? context.fluffyTheme.typography.caption1;

    return OutsetTouchTarget(
      alignment: alignment,
      child: Tappable(
        onTap: onTap,
        semanticLabel: semanticLabel,
        // Said as a button: it does something, it doesn't open a web page.
        semanticButton: onTap != null,
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
                semanticsLabel: switch (semanticLabel) {
                  null => null,
                  _ => '',
                },
                style: style.copyWith(color: context.palette.link),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
