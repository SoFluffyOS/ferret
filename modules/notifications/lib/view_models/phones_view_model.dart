import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/feature/notifications_feature.dart';
import 'package:notifications/view_models/phone_status.dart';
import 'package:protocol/notifications.dart';

/// The connected phones that mirror notifications here, with their settings,
/// for a computer's settings and home card.
class PhonesViewModel extends ChangeNotifier {
  PhonesViewModel({
    required NotificationsFeature feature,
    required Stream<List<Session>> sessionChanges,
  }) : _feature = feature {
    _subscriptions
      ..add(feature.mirrorEvents.listen((_) => _notify()))
      ..add(sessionChanges.listen((_) => _notify()));
  }

  final NotificationsFeature _feature;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  List<PhoneStatus> get phones => [
    for (final session in _feature.senders)
      PhoneStatus(
        deviceId: session.remoteDeviceId,
        name: session.remoteDevice?.name ?? session.remoteDeviceId,
        settings: _feature.senderSettings[session.remoteDeviceId],
        unreachable: _feature.isUnreachable(session.remoteDeviceId),
      ),
  ];

  Future<void> retry(String deviceId) => _feature.fetchSettings(deviceId);

  Future<void> setSkipWhileUsing(String deviceId, bool value) async {
    try {
      await _feature.updateSettings(
        deviceId,
        UpdateMirrorSettings(skipWhileUsing: value),
      );
    } on Object {
      await _feature.fetchSettings(deviceId);
    }
  }

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
