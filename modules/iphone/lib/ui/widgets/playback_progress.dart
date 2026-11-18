import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_iphone/ferret_iphone.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A thin progress bar with the elapsed and total time of what the iPhone
/// plays. The iPhone only says where it was and how fast it goes, so the
/// bar moves on by itself, once a second, and only while playing.
class PlaybackProgress extends StatefulWidget {
  const PlaybackProgress({super.key, required this.media, this.now});

  final AmsState media;

  /// The clock, for tests.
  final DateTime Function()? now;

  @override
  State<PlaybackProgress> createState() => _PlaybackProgressState();
}

class _PlaybackProgressState extends State<PlaybackProgress> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(PlaybackProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    if (widget.media.playback == .paused) {
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
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = context.fluffyTheme.typography.caption2.copyWith(
      color: palette.mutedText,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final now = (widget.now ?? DateTime.now)();
    final position = widget.media.positionAt(now);
    final duration = widget.media.duration;
    final fraction = switch (duration) {
      final duration? when duration > Duration.zero =>
        (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0),
      _ => 0.0,
    };

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: Spacing.d4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Spacing.d2),
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
        Row(
          children: [
            Expanded(child: Text(_format(position), style: style)),
            if (duration != null) Text(_format(duration), style: style),
          ],
        ),
      ],
    );
  }

  static String _format(Duration time) {
    final hours = time.inHours;
    final minutes = time.inMinutes.remainder(60);
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
    }

    return '$minutes:$seconds';
  }
}
