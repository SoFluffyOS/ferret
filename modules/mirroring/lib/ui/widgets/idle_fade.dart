import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Shows [overlay] over [child] while the pointer moves, and fades it out
/// once the pointer rests somewhere else: chrome that gets out of the way
/// of a picture, and never leaves while the pointer is on it.
class IdleFade extends StatefulWidget {
  const IdleFade({
    super.key,
    required this.child,
    required this.overlay,
    this.alignment = Alignment.bottomCenter,
    this.idleAfter = const Duration(seconds: 2),
    this.firstShown = const Duration(seconds: 3),
    this.keepShown = false,
  });

  final Widget child;
  final Widget overlay;
  final Alignment alignment;

  /// How long the pointer rests before the overlay goes.
  final Duration idleAfter;

  /// How long the overlay stays when it first appears, so it is seen once.
  final Duration firstShown;

  /// Holds the overlay, such as while one of its menus is open.
  final bool keepShown;

  @override
  State<IdleFade> createState() => _IdleFadeState();
}

class _IdleFadeState extends State<IdleFade> {
  Timer? _timer;
  bool _shown = true;
  bool _onOverlay = false;

  @override
  void initState() {
    super.initState();
    _hideAfter(widget.firstShown);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _hideAfter(Duration time) {
    _timer?.cancel();
    _timer = Timer(time, _hide);
  }

  void _hide() {
    if (!mounted || _onOverlay || widget.keepShown) {
      return;
    }

    setState(() => _shown = false);
  }

  void _onMoved() {
    _hideAfter(widget.idleAfter);
    if (_shown) {
      return;
    }

    setState(() => _shown = true);
  }

  void _setOnOverlay(bool onOverlay) {
    _onOverlay = onOverlay;
    _onMoved();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _shown || widget.keepShown;

    return MouseRegion(
      onHover: (_) => _onMoved(),
      onEnter: (_) => _onMoved(),
      child: Listener(
        behavior: .translucent,
        onPointerDown: (_) => _onMoved(),
        child: Stack(
          fit: .expand,
          children: [
            widget.child,
            Align(
              alignment: widget.alignment,
              child: MouseRegion(
                onEnter: (_) => _setOnOverlay(true),
                onExit: (_) => _setOnOverlay(false),
                child: IgnorePointer(
                  ignoring: !visible,
                  child: AnimatedOpacity(
                    opacity: switch (visible) {
                      true => 1,
                      false => 0,
                    },
                    duration: FluffyDurations.normal,
                    child: widget.overlay,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
