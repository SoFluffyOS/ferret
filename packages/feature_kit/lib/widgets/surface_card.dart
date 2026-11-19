import 'package:feature_kit/layout/layout.dart';
import 'package:feature_kit/theme/theme.dart';
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

    return Tappable(
      semanticButton: true,
      onTap: onTap,
      focusNode: focusNode,
      hoverOverlayBorderRadius: Corners.card,
      child: card,
    );
  }
}
