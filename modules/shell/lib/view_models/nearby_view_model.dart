import 'dart:async';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:transport/transport.dart';

/// Where pairing with one nearby device stands.
sealed class NearbyAttempt {
  const NearbyAttempt(this.peer);

  final DiscoveredPeer peer;
}

final class NearbyConnecting extends NearbyAttempt {
  const NearbyConnecting(super.peer);
}

/// Both devices show [code]. [confirmedHere] once the user here said they
/// match and only the other device is left to answer.
final class NearbyComparing extends NearbyAttempt {
  const NearbyComparing(super.peer, this.code, {this.confirmedHere = false});

  final String code;
  final bool confirmedHere;
}

final class NearbyPaired extends NearbyAttempt {
  const NearbyPaired(super.peer);
}

final class NearbyFailed extends NearbyAttempt {
  const NearbyFailed(super.peer, this.reason);

  final PairingFailure reason;
}

/// The list of devices near you: who is there, whether Ferret is looking,
/// and pairing with one of them by comparing codes.
class NearbyViewModel extends ChangeNotifier {
  /// With [watch], looks every few seconds for a while, for screens where
  /// the user waits for a device to show up, and keeps this device visible
  /// to the other one meanwhile. Without it, the list follows what the
  /// engine finds on its own.
  NearbyViewModel(
    this._engine, {
    bool watch = true,
    this.lookEvery = const Duration(seconds: 5),
    this.looks = 12,
  }) {
    _changes = _engine.nearbyChanges.listen((_) => notifyListeners());
    if (watch) {
      stayVisible();
      startHearing();
      unawaited(lookAgain());
    }
  }

  static const _pairedFor = Duration(seconds: 4);

  final FerretEngine _engine;

  /// The pause between two looks while watching.
  final Duration lookEvery;

  /// How many times one watch looks before leaving it to the engine, so an
  /// app left open doesn't keep the radio busy.
  final int looks;

  late final StreamSubscription<Object?> _changes;
  NearbyAttempt? _attempt;
  Completer<bool>? _decision;
  Timer? _nextLook;
  Timer? _clearPaired;
  int _looksLeft = 0;
  bool _isLooking = false;
  bool _hasLooked = false;
  bool _disposed = false;
  VisibleHold? _visible;
  MulticastHold? _hearing;

  /// Unpaired devices found on the network, by name. The one being paired
  /// comes first, where its code is in view, and stays listed even after it
  /// stops announcing.
  List<DiscoveredPeer> get peers {
    final found = _engine.nearby
      ..sort(
        (a, b) => a.announce.name.toLowerCase().compareTo(
          b.announce.name.toLowerCase(),
        ),
      );
    final attempt = _attempt;
    if (attempt == null) {
      return found;
    }

    return [
      attempt.peer,
      for (final peer in found)
        if (peer.deviceId != attempt.peer.deviceId) peer,
    ];
  }

  NearbyAttempt? get attempt => _attempt;

  /// Whether a look is under way right now.
  bool get isLooking => _isLooking;

  /// Whether at least one look finished, so "nothing found" is true.
  bool get hasLooked => _hasLooked;

  /// Whether the system keeps Ferret off the local network.
  bool get isBlocked => _engine.isDiscoveryBlocked;

  /// Announces this device while the person pairs, even on a network where
  /// it would only listen: the other device has to find it too.
  void stayVisible() {
    if (_disposed) {
      return;
    }

    _visible ??= _engine.stayVisible();
  }

  /// Lets this device go quiet again where it would be.
  void letGo() {
    _visible?.release();
    _visible = null;
  }

  /// Keeps this device hearing the network while the list is in sight, so
  /// answers and announces from devices nearby reach it. On Android, Wi-Fi
  /// passes them only while someone needs them.
  void startHearing() {
    if (_disposed) {
      return;
    }

    _hearing ??= _engine.multicastNeed.hold('nearby');
  }

  /// The list is out of sight, such as with the app in the background.
  void stopHearing() {
    _hearing?.release();
    _hearing = null;
  }

  /// Looks now, then a few more times.
  Future<void> lookAgain() {
    _looksLeft = looks;
    return _look();
  }

  Future<void> _look() async {
    _nextLook?.cancel();
    if (_disposed || _isLooking) {
      return;
    }

    _isLooking = true;
    _looksLeft--;
    notifyListeners();
    await _engine.scanNearby();
    if (_disposed) {
      return;
    }

    _isLooking = false;
    _hasLooked = true;
    notifyListeners();
    if (_looksLeft > 0) {
      _nextLook = Timer(lookEvery, () => unawaited(_look()));
    }
  }

  /// Starts pairing with [peer]. Both devices then show the same code.
  Future<void> pair(DiscoveredPeer peer) async {
    if (_decision != null) {
      return;
    }

    final decision = Completer<bool>();
    _decision = decision;
    _clearPaired?.cancel();
    _set(NearbyConnecting(peer));

    final outcome = await _engine.pairWithAddress(
      peer.host,
      peer.port,
      expectedDeviceId: peer.deviceId,
      onCode: (code) {
        _set(NearbyComparing(peer, code));
        return decision.future;
      },
    );
    _decision = null;
    if (!decision.isCompleted) {
      decision.complete(false);
    }

    switch (outcome) {
      case Paired():
        _set(NearbyPaired(peer));
        _clearPaired = Timer(_pairedFor, dismiss);
      case PairingFailed(reason: .cancelled):
        _set(null);
      case PairingFailed(:final reason):
        _set(NearbyFailed(peer, reason));
    }
  }

  /// The user saw the same code on the other device.
  void confirm() {
    final (attempt, decision) = (_attempt, _decision);
    if (attempt is! NearbyComparing ||
        decision == null ||
        decision.isCompleted) {
      return;
    }

    decision.complete(true);
    _set(NearbyComparing(attempt.peer, attempt.code, confirmedHere: true));
  }

  /// Gives up before confirming: the codes differ, or the user changed
  /// their mind.
  void cancel() {
    final decision = _decision;
    if (decision == null || decision.isCompleted) {
      return;
    }

    decision.complete(false);
  }

  /// Clears a finished attempt from the list.
  void dismiss() {
    if (_decision != null) {
      return;
    }

    _set(null);
  }

  void _set(NearbyAttempt? attempt) {
    if (_disposed) {
      return;
    }

    _attempt = attempt;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    letGo();
    stopHearing();
    cancel();
    _nextLook?.cancel();
    _clearPaired?.cancel();
    unawaited(_changes.cancel());
    super.dispose();
  }
}
