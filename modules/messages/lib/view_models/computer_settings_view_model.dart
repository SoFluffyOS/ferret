import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/services.dart';

/// Messages settings on a computer: notices, and forgetting saved texts.
class ComputerSettingsViewModel extends ChangeNotifier {
  ComputerSettingsViewModel({
    required MessagesSettings settings,
    required MessageLibrary library,
  }) : _settings = settings,
       _library = library {
    _subscriptions
      ..add(settings.changes.listen((_) => _notify()))
      ..add(library.events.listen((_) => _notify()));
  }

  final MessagesSettings _settings;
  final MessageLibrary _library;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  bool get notify => _settings.notify;

  bool get hasSavedTexts => _library.deviceIds.any(_library.hasHistory);

  Future<void> setNotify(bool value) => _settings.setNotify(value);

  Future<void> forgetSavedTexts() => _library.forgetAll();

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
