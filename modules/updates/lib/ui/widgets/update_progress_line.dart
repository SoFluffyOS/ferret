import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What the update is doing, over a bar: filling while it downloads,
/// moving while it checks or installs.
class UpdateProgressLine extends StatelessWidget {
  const UpdateProgressLine({super.key, required this.label, this.progress});

  final String label;

  /// 0 to 1, or null when there is no share to show.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(label, style: typography.caption1.copyWith(color: palette.text)),
          Spacing.v8,
          FluffyProgressBar(value: progress, minHeight: Spacing.d4),
        ],
      ),
    );
  }
}
