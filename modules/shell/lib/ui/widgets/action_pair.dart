import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Two answers to one question, such as "Cancel" and "They match": side by
/// side, the real next step on the right. With text set large they no
/// longer fit next to each other, so they stack, the next step on top.
class ActionPair extends StatelessWidget {
  const ActionPair({
    super.key,
    required this.ghostLabel,
    required this.onGhost,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final String ghostLabel;
  final VoidCallback? onGhost;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final ghost = Button(
      variant: .ghost,
      label: ghostLabel,
      mainAxisSize: .max,
      titleExpand: .shrink,
      onPressed: onGhost,
    );
    final primary = Button(
      variant: .primary,
      label: primaryLabel,
      mainAxisSize: .max,
      titleExpand: .shrink,
      onPressed: onPrimary,
    );
    if (context.hasLargeText) {
      return Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [primary, Spacing.v8, ghost],
      );
    }

    return Row(
      children: [
        Expanded(child: ghost),
        Spacing.h12,
        Expanded(child: primary),
      ],
    );
  }
}
