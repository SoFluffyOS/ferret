import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/bootstrap/boot_failure.dart';

/// Starts Ferret on a Mac. The popover and the window show nothing until
/// the whole app is ready, never half of it; when starting fails, the
/// popover says so, with Try again, instead of staying empty.
abstract final class MenubarBoot {
  static Future<void> run(Future<Widget> Function() start) async {
    try {
      runWidget(await start());
      return;
    } on Object catch (error, stackTrace) {
      printError('Ferret could not start', error, stackTrace);
    }

    final popover = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (popover == null) {
      return;
    }

    runWidget(
      View(
        view: popover,
        child: _MenubarRetry(start: start),
      ),
    );
  }
}

class _MenubarRetry extends StatefulWidget {
  const _MenubarRetry({required this.start});

  final Future<Widget> Function() start;

  @override
  State<_MenubarRetry> createState() => _MenubarRetryState();
}

class _MenubarRetryState extends State<_MenubarRetry> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    try {
      runWidget(await widget.start());
    } on Object catch (error, stackTrace) {
      printError('Ferret could not start', error, stackTrace);
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BootFailure(
      onRetry: () => unawaited(_retry()),
      isRetrying: _isRetrying,
    );
  }
}
