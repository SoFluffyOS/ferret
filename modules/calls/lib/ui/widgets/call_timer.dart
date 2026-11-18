import 'dart:async';

import 'package:calls/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

/// The time since [since] as `m:ss`, counting every second.
class CallTimer extends StatefulWidget {
  const CallTimer({super.key, required this.since, this.style});

  final DateTime since;
  final TextStyle? style;

  @override
  State<CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends State<CallTimer> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = .periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    formatCallDuration(DateTime.now().difference(widget.since)),
    style: widget.style,
  );
}
