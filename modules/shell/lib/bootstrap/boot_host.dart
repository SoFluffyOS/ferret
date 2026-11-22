import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/bootstrap/boot_failure.dart';
import 'package:shell/bootstrap/boot_screen.dart';
import 'package:shell/bootstrap/splash_look.dart';

/// The root widget from Ferret's very first frame: [BootScreen] while
/// [start] gets everything ready, then the app [start] returns, faded in
/// under it the way the system's own splash fades out. When [start]
/// throws, [BootFailure] says so and tries again on request.
class BootHost extends StatefulWidget {
  const BootHost({
    super.key,
    required this.start,
    this.look,
    this.spinnerAfter = const Duration(seconds: 1),
  });

  /// Gets Ferret ready and returns its app. Called again on Try again, so
  /// it must clean up after itself when it fails.
  final Future<Widget> Function() start;

  /// The launch screen to carry on; a window's background when null.
  final SplashLook? look;

  final Duration spinnerAfter;

  @override
  State<BootHost> createState() => _BootHostState();
}

class _BootHostState extends State<BootHost>
    with SingleTickerProviderStateMixin {
  static const _reveal = Duration(milliseconds: 250);

  late final AnimationController _cover = AnimationController(
    vsync: this,
    duration: _reveal,
    value: 1,
  );
  Widget? _app;
  bool _hasFailed = false;
  bool _isRetrying = false;
  bool _isCovered = true;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _cover.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final Widget app;
    try {
      app = await widget.start();
    } on Object catch (error, stackTrace) {
      printError('Ferret could not start', error, stackTrace);
      if (mounted) {
        setState(() {
          _hasFailed = true;
          _isRetrying = false;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _app = app);
    await _uncover();
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    await _start();
  }

  Future<void> _uncover() async {
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _cover.animateTo(0, curve: Curves.easeOut);
    }

    if (mounted) {
      setState(() => _isCovered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The app brings its own direction with its language; this one is
    // only for the cover's own layout.
    return Directionality(
      textDirection: .ltr,
      child: Stack(
        fit: .expand,
        children: [
          if (_app case final app?)
            KeyedSubtree(key: const ValueKey('app'), child: app),
          if (_isCovered)
            IgnorePointer(
              key: const ValueKey('cover'),
              ignoring: _app != null,
              child: FadeTransition(opacity: _cover, child: _coverPage()),
            ),
        ],
      ),
    );
  }

  Widget _coverPage() {
    // After a failure, the page stays until the app shows under it.
    if (_hasFailed) {
      return BootFailure(
        onRetry: () => unawaited(_retry()),
        isRetrying: _isRetrying,
      );
    }

    return BootScreen(look: widget.look, spinnerAfter: widget.spinnerAfter);
  }
}
