import 'dart:async';

import 'package:find/ui/pages/pages.dart';
import 'package:find/view_models/view_models.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Puts the ringing screen on top of the app while this device rings, and
/// takes it away when the ring ends. Closed by hand, it stays closed for
/// that ring.
class RingingOverlay {
  RingingOverlay({required this.viewModel, required this.navigatorKey});

  final FindViewModel viewModel;
  final GlobalKey<NavigatorState> navigatorKey;

  Route<void>? _route;

  /// The start of the ring the screen was shown for.
  DateTime? _shownFor;

  void start() {
    viewModel.addListener(_sync);
    _sync();
  }

  void dispose() => viewModel.removeListener(_sync);

  void _sync() {
    final ring = viewModel.localRing;
    if (!ring.isRinging) {
      _close();
      return;
    }

    if (_shownFor == ring.startedAt) {
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _shownFor = ring.startedAt;
    final route = PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const RingingPage(),
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

  void _close() {
    final route = _route;
    _route = null;
    if (route == null || !route.isActive) {
      return;
    }

    route.navigator?.removeRoute(route);
  }
}
