import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds every second with the time left until [until], so a wait
/// shows its own clock. [builder] gets zero once the time is up.
class Countdown extends StatefulWidget {
  const Countdown({
    super.key,
    required this.until,
    required this.builder,
    this.clock,
  });

  final DateTime until;
  final Widget Function(BuildContext context, Duration left) builder;
  final DateTime Function()? clock;

  /// "0:48", the way a phone's own timer reads.
  static String clockText(Duration left) {
    final seconds = left.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${left.inMinutes}:$seconds';
  }

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  static const _second = Duration(seconds: 1);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = .periodic(_second, (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _left {
    final now = widget.clock?.call() ?? DateTime.now();
    final left = widget.until.difference(now);
    if (left.isNegative) {
      return Duration.zero;
    }

    // Counted up to the whole second, so the clock starts at its full
    // time and reads zero only when the time is really up.
    return Duration(seconds: (left.inMilliseconds / 1000).ceil());
  }

  void _tick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _left);
}
