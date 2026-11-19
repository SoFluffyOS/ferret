import 'dart:async';

import 'package:actions/models/models.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds once a second with the whole seconds [countdown] has left.
class SecondsLeft extends StatefulWidget {
  const SecondsLeft({
    super.key,
    required this.countdown,
    required this.builder,
    this.clock = DateTime.now,
  });

  final ActionCountdown countdown;
  final Widget Function(BuildContext context, int seconds) builder;
  final DateTime Function() clock;

  @override
  State<SecondsLeft> createState() => _SecondsLeftState();
}

class _SecondsLeftState extends State<SecondsLeft> {
  static const _tick = Duration(milliseconds: 250);

  late Timer _timer;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = widget.countdown.secondsLeft(widget.clock());
    _timer = .periodic(_tick, (_) => _update());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _update() {
    final seconds = widget.countdown.secondsLeft(widget.clock());
    if (seconds == _seconds) {
      return;
    }

    setState(() => _seconds = seconds);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _seconds);
}
