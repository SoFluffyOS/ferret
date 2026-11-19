import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/feature/notifications_feature.dart';
import 'package:notifications/view_models/phone_status.dart';

/// A paired Android phone, by id and name.
typedef PairedPhone = ({String deviceId, String name});

/// The phones that mirror notifications here, with their settings, for a
/// computer's settings and home card.
class PhonesViewModel extends ChangeNotifier {
  PhonesViewModel({
    required NotificationsFeature feature,
    required Stream<List<Session>> sessionChanges,
    List<PairedPhone> Function()? pairedPhones,
    Stream<Object?>? pairingChanges,
  }) : _feature = feature,
       _pairedPhones = pairedPhones ?? _none {
    _subscriptions
      ..add(feature.mirrorEvents.listen((_) => _notify()))
      ..add(sessionChanges.listen((_) => _notify()));
    if (pairingChanges case final changes?) {
      _subscriptions.add(changes.listen((_) => _notify()));
    }
  }

  final NotificationsFeature _feature;
  final List<PairedPhone> Function() _pairedPhones;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _disposed = false;

  /// Connected phones that offer to mirror here.
  List<PhoneStatus> get phones => [
    for (final session in _feature.senders)
      PhoneStatus(
        deviceId: session.remoteDeviceId,
        name: _feature.host.displayNameOf(session.remoteDeviceId),
        settings: _feature.senderSettings[session.remoteDeviceId],
        unreachable: _feature.isUnreachable(session.remoteDeviceId),
      ),
  ];

  /// Every paired Android phone, connected or not, then any other connected
  /// device that mirrors here.
  List<PhoneStatus> get pairedPhones {
    final connected = {for (final phone in phones) phone.deviceId: phone};
    final paired = [
      for (final phone in _pairedPhones())
        connected[phone.deviceId] ??
            PhoneStatus(
              deviceId: phone.deviceId,
              name: phone.name,
              settings: null,
              unreachable: false,
              online: _feature.isConnected(phone.deviceId),
              sends: false,
            ),
    ];
    final pairedIds = {for (final phone in paired) phone.deviceId};

    return [
      ...paired,
      for (final phone in phones)
        if (!pairedIds.contains(phone.deviceId)) phone,
    ];
  }

  Future<void> retry(String deviceId) => _feature.fetchSettings(deviceId);

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

  static List<PairedPhone> _none() => const [];
}
