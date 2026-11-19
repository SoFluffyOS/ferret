import 'dart:async';

import 'package:flutter/widgets.dart';

/// Builds a space whose chrome shows while the pointer moves over it,
/// and fades once the pointer rests or leaves: chrome that gets quiet
/// beside a picture. [builder] gets whether the chrome shows, and a
/// callback to say the pointer is on the chrome itself, which keeps it.
class IdleFade extends StatefulWidget {
  const IdleFade({
    super.key,
    required this.builder,
    this.idleAfter = const Duration(seconds: 2),
    this.firstShown = const Duration(seconds: 3),
    this.keepShown = false,
  });

  final Widget Function(
    BuildContext context,
    bool shown,
    ValueChanged<bool> onChrome,
  )
  builder;

  /// How long the pointer rests before the chrome goes quiet.
  final Duration idleAfter;

  /// How long the chrome stays when it first appears, so it is seen once.
  final Duration firstShown;

  /// Holds the chrome, such as while one of its menus is open.
  final bool keepShown;

  @override
  State<IdleFade> createState() => _IdleFadeState();
}

class _IdleFadeState extends State<IdleFade> {
  Timer? _timer;
  bool _shown = true;
  bool _onChrome = false;

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
    if (!mounted || _onChrome || widget.keepShown) {
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

  void _setOnChrome(bool onChrome) {
    _onChrome = onChrome;
    _onMoved();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown || widget.keepShown;

    return MouseRegion(
      onHover: (_) => _onMoved(),
      onEnter: (_) => _onMoved(),
      onExit: (_) => _hideAfter(widget.idleAfter),
      child: Listener(
        behavior: .translucent,
        onPointerDown: (_) => _onMoved(),
        child: widget.builder(context, shown, _setOnChrome),
      ),
    );
  }
}
