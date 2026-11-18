import 'dart:async';

import 'package:flutter/foundation.dart';

/// Turns a feature's change stream into a [Listenable] for
/// [FeatureUi.uiChanges], so the shell rebuilds the card and health chips.
class FeatureChanges extends ChangeNotifier {
  FeatureChanges(Stream<Object?> source) {
    _subscription = source.listen((_) => _notify());
  }

  late final StreamSubscription<Object?> _subscription;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }
}
