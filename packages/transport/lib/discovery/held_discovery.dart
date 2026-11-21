import 'dart:async';

import 'package:protocol/protocol.dart';
import 'package:transport/discovery/discovered_peer.dart';

/// Holds [inner] back until [release]: starting only remembers what to
/// announce. For an iPhone, where the first packet on the local network
/// makes iOS ask about it, so Ferret waits until the person reached a
/// place that looks for devices and read why.
class HeldDiscovery implements ActiveDiscovery {
  HeldDiscovery(this.inner, {bool released = false}) : _released = released {
    inner.peers.listen(_peers.add);
    if (inner case final ActiveDiscovery active) {
      active.departures.listen(_departures.add);
    }
  }

  final Discovery inner;
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  final StreamController<String> _departures = .broadcast();
  bool _released;
  Announce? _wanted;
  bool _running = false;

  /// Whether [inner] may run.
  bool get isReleased => _released;

  /// Whether [inner] runs right now.
  bool get isRunning => _running;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Stream<String> get departures => _departures.stream;

  /// Nothing held back is blocked: it hasn't asked yet.
  @override
  bool get isBlocked => switch (inner) {
    final ActiveDiscovery active when _running => active.isBlocked,
    _ => false,
  };

  /// Lets [inner] run, starting it now when [start] was already called.
  Future<void> release() async {
    if (_released) {
      return;
    }

    _released = true;
    if (_wanted case final self?) {
      await _startInner(self);
    }
  }

  @override
  Future<void> start(Announce self) async {
    _wanted = self;
    if (!_released) {
      return;
    }

    await _startInner(self);
  }

  @override
  Future<void> announceNow() async {
    if (_running) {
      await inner.announceNow();
    }
  }

  @override
  Future<void> scan() async {
    if (!_running) {
      return;
    }

    switch (inner) {
      case final ActiveDiscovery active:
        await active.scan();
      default:
        await inner.announceNow();
    }
  }

  @override
  Future<void> stop() async {
    _wanted = null;
    if (!_running) {
      return;
    }

    _running = false;
    await inner.stop();
  }

  Future<void> _startInner(Announce self) async {
    _running = true;
    await inner.start(self);
  }
}
