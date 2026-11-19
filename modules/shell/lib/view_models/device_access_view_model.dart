import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';

/// What one paired device may use on this one, feature by feature, and
/// turning things off for it.
class DeviceAccessViewModel extends ChangeNotifier {
  DeviceAccessViewModel({
    required DeviceAccess access,
    required this.deviceId,
    required List<String> featureIds,
  }) : _access = access,
       featureIds = List.unmodifiable(featureIds) {
    _subscription = access.changes
        .where((changed) => changed == deviceId)
        .listen((_) => notifyListeners());
  }

  final DeviceAccess _access;
  final String deviceId;

  /// The features listed, in the order shown.
  final List<String> featureIds;
  late final StreamSubscription<String> _subscription;

  bool isAllowed(String featureId) => !_access.isBlocked(deviceId, featureId);

  int get offCount => featureIds.where((id) => !isAllowed(id)).length;

  bool get allOff => featureIds.isNotEmpty && offCount == featureIds.length;

  Future<void> setAllowed(String featureId, bool allowed) =>
      _access.setAllowed(deviceId, featureId, allowed: allowed);

  /// One tap for "this device gets nothing from me", short of forgetting it.
  Future<void> turnAllOff() => _access.blockAll(deviceId, featureIds);

  Future<void> turnAllOn() => _access.forget(deviceId);

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
