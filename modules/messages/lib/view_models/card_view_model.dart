import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:messages/models/models.dart';
import 'package:messages/services/services.dart';
import 'package:protocol/messages.dart';

/// One phone on the computer's home card.
class PhoneSummary {
  const PhoneSummary({
    required this.deviceId,
    required this.name,
    required this.readiness,
    required this.unread,
    this.latest,
  });

  final String deviceId;
  final String name;
  final PhoneReadiness readiness;
  final int unread;
  final Conversation? latest;
}

/// The computer's home card: each phone that shares texts, its unread count
/// and its latest conversation.
class CardViewModel extends ChangeNotifier {
  CardViewModel({
    required MessageLibrary library,
    required String Function(String deviceId) deviceName,
    required bool Function(String deviceId) isPaired,
  }) : _library = library,
       _deviceName = deviceName,
       _isPaired = isPaired {
    _subscription = library.events.listen((_) => _notify());
  }

  final MessageLibrary _library;
  final String Function(String deviceId) _deviceName;
  final bool Function(String deviceId) _isPaired;
  late final StreamSubscription<LibraryEvent> _subscription;
  bool _disposed = false;

  List<PhoneSummary> get phones => [
    for (final deviceId in _library.deviceIds)
      if (_isPaired(deviceId) && _shows(deviceId))
        PhoneSummary(
          deviceId: deviceId,
          name: _deviceName(deviceId),
          readiness: _library.phone(deviceId).readiness,
          unread: _library.unreadTotal(deviceId),
          latest: _library.cache(deviceId).conversations.firstOrNull,
        ),
  ];

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  bool _shows(String deviceId) =>
      _library.hasHistory(deviceId) || _library.phone(deviceId).connected;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
