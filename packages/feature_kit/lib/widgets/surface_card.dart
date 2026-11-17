import 'package:feature_kit/theme/theme.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A filled card with no border.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(Spacing.d12),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(Spacing.d12),
        child: child,
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Tappable(onTap: onTap, child: card);
  }
}
