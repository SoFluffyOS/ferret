import 'dart:async';

import 'package:flutter/widgets.dart';

/// Opens what a file drag rests on, as Finder's spring-loaded folders do:
/// once [active] has stayed true for [delay], [onOpen] runs.
class DropSpringOpen extends StatefulWidget {
  const DropSpringOpen({
    super.key,
    required this.active,
    required this.onOpen,
    required this.child,
    this.delay = const Duration(milliseconds: 600),
  });

  final bool active;
  final VoidCallback onOpen;
  final Duration delay;
  final Widget child;

  @override
  State<DropSpringOpen> createState() => _DropSpringOpenState();
}

class _DropSpringOpenState extends State<DropSpringOpen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(DropSpringOpen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) {
      return;
    }

    _arm();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    _timer = null;
    if (!widget.active) {
      return;
    }

    _timer = Timer(widget.delay, widget.onOpen);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
