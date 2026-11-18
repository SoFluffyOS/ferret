import 'dart:async';

import 'package:find/feature/find_feature.dart';
import 'package:find/models/models.dart';
import 'package:flutter/foundation.dart';

/// What the home card, the ringing screen and a device's ring page show,
/// and what they can do.
class FindViewModel extends ChangeNotifier {
  FindViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => notifyListeners());
  }

  final FindFeature feature;
  late final StreamSubscription<void> _subscription;

  LocalRing get localRing => feature.localRing;

  bool get isRingingHere => feature.localRing.isRinging;

  List<OutgoingRing> get outgoing => feature.outgoing;

  OutgoingRing? outgoingFor(String deviceId) => feature.outgoingFor(deviceId);

  Future<void> ring(String deviceId) => feature.ring(deviceId);

  Future<void> stop(String deviceId) => feature.stopRinging(deviceId);

  Future<void> foundIt() => feature.foundIt();

  void dismiss(String deviceId) => feature.dismiss(deviceId);

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
