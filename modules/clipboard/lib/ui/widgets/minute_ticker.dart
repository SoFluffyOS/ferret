import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds once a minute while shown, so "2 min ago" stays true.
class MinuteTicker extends StatefulWidget {
  const MinuteTicker({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<MinuteTicker> createState() => _MinuteTickerState();
}

class _MinuteTickerState extends State<MinuteTicker> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = .periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}
