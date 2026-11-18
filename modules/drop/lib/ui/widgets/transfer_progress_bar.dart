import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A thin bar showing how far a transfer got.
class TransferProgressBar extends StatelessWidget {
  const TransferProgressBar({
    super.key,
    required this.progress,
    required this.color,
  });

  /// 0 to 1.
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Spacing.d2);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: Spacing.d4,
        child: Stack(
          fit: .expand,
          children: [
            ColoredBox(color: context.palette.background),
            FractionallySizedBox(
              alignment: .centerLeft,
              widthFactor: progress.clamp(0, 1).toDouble(),
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
