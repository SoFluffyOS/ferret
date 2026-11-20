import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/focus_rings.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A filled card with no border: the design system's `RoundCard` in
/// Ferret's surface colour.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.focusNode,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  /// The keyboard focus of a card that has [onTap].
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final card = RoundCard(
      color: context.palette.surface,
      borderRadius: Corners.card,
      padding: padding ?? EdgeInsets.all(Spacing.d12),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    // Focus on a button inside the card is that button's: the card draws
    // its ring, and grows a little, only while it holds focus itself.
    return PrimaryFocusBuilder(
      focusNode: focusNode,
      builder: (context, node) => Tappable(
        semanticButton: true,
        onTap: onTap,
        focusNode: node,
        enableAnimation: !node.focusIsInside,
        enableFocusBorder: false,
        hoverOverlayBorderRadius: Corners.card,
        builder: (context, state) => DecoratedBox(
          position: .foreground,
          decoration: ShapeDecoration(
            shape: Corners.shape(
              Corners.card,
              side: switch (state == .focus && node.hasPrimaryFocus) {
                true => BorderSide(
                  color: context.palette.accent,
                  width: Spacing.d2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                false => BorderSide.none,
              },
            ),
          ),
          child: card,
        ),
      ),
    );
  }
}
