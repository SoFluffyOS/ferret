import 'dart:async';

import 'package:ferret_wake/ferret_wake.dart';
import 'package:flutter/foundation.dart';

/// What the wake feature shows: attempts under way, this computer's cards,
/// and its two switches.
class WakeViewModel extends ChangeNotifier {
  WakeViewModel(this.feature) {
    _subscription = feature.changes.listen((_) => notifyListeners());
  }

  final WakeFeature feature;
  late final StreamSubscription<void> _subscription;

  List<NetworkCard> get cards => feature.cards;

  bool get shares => feature.settings.shares;

  bool get relays => feature.settings.relays;

  WakeAttempt? attemptFor(String deviceId) => feature.attemptFor(deviceId);

  Future<void> wake(String deviceId) => feature.wake(deviceId);

  Future<void> setShares(bool shares) => feature.setShares(shares);

  Future<void> setRelays(bool relays) => feature.setRelays(relays);

  /// Reads this computer's cards again, such as when Settings opens after
  /// the person changed something in the system.
  Future<void> refresh() => feature.refreshCards();

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
