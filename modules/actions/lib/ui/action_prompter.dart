import 'dart:async';

import 'package:actions/l10n/l10n.dart';
import 'package:actions/models/models.dart';
import 'package:actions/ui/dialogs/dialogs.dart';
import 'package:actions/view_models/view_models.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Puts the question ("Let Pixel 7 restart this Mac?") and then the
/// countdown on top of the app, and takes each away once it is answered
/// anywhere: the dialog, the notice or the home card. A question closed by
/// hand stays closed; a countdown can only be cancelled.
class ActionPrompter {
  ActionPrompter({required this.viewModel, required this.navigatorKey});

  final ActionsViewModel viewModel;
  final GlobalKey<NavigatorState> navigatorKey;

  Route<void>? _route;

  /// When what the dialog shows (a question or a countdown) started.
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
    final countdown = viewModel.countdown;
    final startedAt = countdown?.startedAt ?? pending?.askedAt;
    if (startedAt == null) {
      _shownFor = null;
      _close();
      return;
    }

    if (_shownFor == startedAt) {
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _shownFor = startedAt;
    _close();
    final route = RawDialogRoute<void>(
      barrierDismissible: countdown == null,
      barrierLabel: platformActionsL10n().dismiss,
      barrierColor: FluffyColors.barrier,
      transitionDuration: FluffyDurations.dialogTransition,
      pageBuilder: (_, _, _) => _dialog(pending, countdown),
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

  Widget _dialog(ActionAsk? pending, ActionCountdown? countdown) {
    if (countdown != null) {
      return CountdownDialog(
        countdown: countdown,
        onCancel: viewModel.cancelCountdown,
      );
    }

    if (pending != null) {
      return ActionConsentDialog(ask: pending, onAnswer: _answer);
    }

    return const SizedBox.shrink();
  }

  void _answer(ActionChoice choice) {
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
