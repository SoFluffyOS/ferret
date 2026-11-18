import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/models/models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Three bars that say how the picture is doing: all filled is good.
class QualityMark extends StatelessWidget {
  const QualityMark({super.key, required this.quality});

  static const _barCount = 3;

  final ViewQuality quality;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final filled = switch (quality) {
      .good => palette.text,
      .slow => palette.warning,
      .poor => palette.danger,
    };

    return Row(
      mainAxisSize: .min,
      crossAxisAlignment: .end,
      children: [
        for (var bar = 0; bar < _barCount; bar++) ...[
          if (bar > 0) Spacing.horizontal(Spacing.d2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: switch (bar < quality.bars) {
                true => filled,
                false => palette.mutedText.withValues(alpha: 0.35),
              },
              borderRadius: BorderRadius.circular(Spacing.d1),
            ),
            child: SizedBox(
              width: Spacing.d3,
              height: Spacing.d6 + Spacing.d3 * bar,
            ),
          ),
        ],
      ],
    );
  }
}
