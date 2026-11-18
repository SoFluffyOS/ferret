import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/ui/widgets/widgets.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Puts "Let Pixel control this computer?" on top of the app when a device
/// asks, and takes it away once answered anywhere: the dialog, the notice
/// or the home card. Closed by hand, it stays closed for that request.
class ConsentPrompter {
  ConsentPrompter({required this.viewModel, required this.navigatorKey});

  final HostViewModel viewModel;
  final GlobalKey<NavigatorState> navigatorKey;

  Route<void>? _route;

  /// When the request the dialog was shown for was made.
  DateTime? _shownFor;

  void start() {
    viewModel.addListener(_sync);
    _sync();
  }

  void dispose() {
    viewModel.removeListener(_sync);
    _close();
  }

  void _sync() {
    final pending = viewModel.pending;
    if (pending == null) {
      _close();
      return;
    }

    if (_shownFor == pending.askedAt) {
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _shownFor = pending.askedAt;
    _close();
    final route = RawDialogRoute<void>(
      barrierDismissible: true,
      barrierLabel: platformRemoteInputL10n().dismiss,
      barrierColor: FluffyColors.barrier,
      transitionDuration: FluffyDurations.dialogTransition,
      pageBuilder: (_, _, _) => ConsentDialog(
        deviceName: pending.deviceName,
        onAnswer: _answer,
      ),
    );
    _route = route;
    unawaited(
      navigator.push(route).then((_) {
        if (_route == route) {
          _route = null;
        }
      }),
    );
  }

  void _answer(ConsentChoice choice) {
    _close();
    unawaited(viewModel.answer(choice));
  }

  void _close() {
    final route = _route;
    _route = null;
    if (route == null || !route.isActive) {
      return;
    }

    route.navigator?.removeRoute(route);
  }
}
