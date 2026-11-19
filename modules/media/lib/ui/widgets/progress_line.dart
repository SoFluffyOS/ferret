import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A thin progress bar with the elapsed and total time. Ticks once a second
/// only while playing; tapping it seeks when [onSeek] is set.
class ProgressLine extends StatefulWidget {
  const ProgressLine({
    super.key,
    required this.positionAt,
    required this.now,
    required this.durationMs,
    required this.playing,
    this.onSeek,
  });

  /// The position at a time on this device's clock.
  final int Function(int nowMs) positionAt;
  final int Function() now;
  final int durationMs;
  final bool playing;
  final ValueChanged<int>? onSeek;

  @override
  State<ProgressLine> createState() => _ProgressLineState();
}

class _ProgressLineState extends State<ProgressLine> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(ProgressLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    if (!widget.playing) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }

    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = context.fluffyTheme.typography.caption2.copyWith(
      color: palette.mutedText,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final positionMs = widget.positionAt(widget.now());
    final durationMs = widget.durationMs;
    final fraction = switch (durationMs > 0) {
      true => (positionMs / durationMs).clamp(0.0, 1.0),
      false => 0.0,
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: .opaque,
            onTapUp: switch ((widget.onSeek, durationMs > 0)) {
              (final onSeek?, true) => (details) {
                final ratio = (details.localPosition.dx / constraints.maxWidth)
                    .clamp(0.0, 1.0);
                onSeek((durationMs * ratio).round());
              },
              _ => null,
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.d4),
              child: ClipRSuperellipse(
                borderRadius: Corners.radius(Corners.capsule),
                child: SizedBox(
                  height: Spacing.d4,
                  child: Stack(
                    fit: .expand,
                    children: [
                      ColoredBox(color: palette.background),
                      FractionallySizedBox(
                        alignment: .centerLeft,
                        widthFactor: fraction,
                        child: ColoredBox(color: palette.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(child: Text(_format(positionMs), style: style)),
            if (durationMs > 0) Text(_format(durationMs), style: style),
          ],
        ),
      ],
    );
  }

  static String _format(int ms) {
    final total = ms ~/ 1000;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = (total % 60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
    }

    return '$minutes:$seconds';
  }
}
