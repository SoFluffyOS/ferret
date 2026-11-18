import 'dart:async';

import 'package:calls/feature/calls_feature.dart';
import 'package:flutter/foundation.dart';

/// The Calls options on a computer.
class CallsSettingsViewModel extends ChangeNotifier {
  CallsSettingsViewModel(this._feature) {
    _subscription = _feature.changes.listen((_) => notifyListeners());
  }

  final CallsFeature _feature;
  late final StreamSubscription<void> _subscription;

  bool get showIncoming => _feature.settings.showIncoming;

  Future<void> setShowIncoming(bool value) =>
      _feature.settings.setShowIncoming(value);

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
