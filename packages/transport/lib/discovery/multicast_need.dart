import 'dart:async';

/// Whether this device needs to hear multicast and broadcast from the
/// network right now. Android drops those packets to save battery unless an
/// app holds a lock, so Ferret holds it only while this says so: while a
/// screen looks for devices nearby ([hold]), or while a paired device is
/// missing and may come back ([setMissing]). Never while stopped, such as
/// during a pause ([setRunning]).
///
/// Sending needs none of this: announces go out either way.
class MulticastNeed {
  final StreamController<bool> _changes = .broadcast();
  final Map<String, int> _holds = {};
  bool _running = false;
  bool _missing = false;
  bool _needed = false;

  /// Whether something needs to hear the network now.
  bool get isNeeded => _needed;

  /// Fires with [isNeeded] each time it changes.
  Stream<bool> get changes => _changes.stream;

  /// Why it is needed: each reason held, plus `missing` for a paired device
  /// that isn't connected. Empty while stopped.
  List<String> get reasons => [
    if (_running) ...[
      if (_missing) 'missing',
      ..._holds.keys,
    ],
  ];

  /// Keeps it needed until the hold is released, for as long as a screen
  /// that lists devices nearby is in sight, or a scan waits for answers.
  /// Holds with the same [reason] add up.
  MulticastHold hold(String reason) {
    _holds.update(reason, (count) => count + 1, ifAbsent: () => 1);
    _update();
    return MulticastHold._(() {
      final count = (_holds[reason] ?? 1) - 1;
      if (count <= 0) {
        _holds.remove(reason);
      } else {
        _holds[reason] = count;
      }
      _update();
    });
  }

  /// Whether at least one paired device isn't connected, so its announce
  /// has to be heard when it comes back.
  void setMissing(bool missing) {
    _missing = missing;
    _update();
  }

  /// Whether Ferret is on the network at all. Off, such as while paused,
  /// nothing needs to be heard.
  void setRunning(bool running) {
    _running = running;
    _update();
  }

  void _update() {
    final needed = _running && (_missing || _holds.isNotEmpty);
    if (needed == _needed) {
      return;
    }

    _needed = needed;
    _changes.add(needed);
  }
}

/// Keeps a [MulticastNeed] needed until [release].
class MulticastHold {
  MulticastHold._(this._onRelease);

  final void Function() _onRelease;
  bool _released = false;

  /// Only the first call counts.
  void release() {
    if (_released) {
      return;
    }

    _released = true;
    _onRelease();
  }
}
