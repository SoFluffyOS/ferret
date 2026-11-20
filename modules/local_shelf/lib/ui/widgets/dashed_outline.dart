import 'dart:ui' as ui;

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// A dashed line just inside a shape of continuous corners: the sign of
/// an empty place to drop things on, as in Finder and Files.
class DashedOutline extends StatelessWidget {
  const DashedOutline({
    super.key,
    required this.radius,
    required this.color,
    required this.child,
    this.width = 1.5,
    this.dash = 6,
    this.gap = 4,
  });

  final double radius;
  final Color color;
  final double width;
  final double dash;
  final double gap;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashPainter(
      radius: radius,
      color: color,
      width: width,
      dash: dash,
      gap: gap,
    ),
    child: child,
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter({
    required this.radius,
    required this.color,
    required this.width,
    required this.dash,
    required this.gap,
  });

  final double radius;
  final Color color;
  final double width;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final path = Corners.shape(radius - width / 2).getOuterPath(rect);
    final paint = Paint()
      ..color = color
      ..style = .stroke
      ..strokeWidth = width
      ..strokeCap = .round;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      // Whole dashes all the way round, so the line meets where it began.
      final count = (metric.length / (dash + gap)).floor().clamp(1, 1 << 20);
      final step = metric.length / count;
      final length = step * dash / (dash + gap);
      for (var start = 0.0; start < metric.length - 0.1; start += step) {
        canvas.drawPath(metric.extractPath(start, start + length), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.color != color ||
      oldDelegate.width != width ||
      oldDelegate.dash != dash ||
      oldDelegate.gap != gap;
}
