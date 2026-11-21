import 'dart:async';

import 'package:core/core.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/discovery/discovered_peer.dart';

/// Uses [preferred], or [fallback] when that can't start. Only one of them
/// runs, for two ways that must not both offer the same thing, such as the
/// system's Bonjour and Ferret's own DNS-SD offering one service name.
class FallbackDiscovery implements ActiveDiscovery {
  FallbackDiscovery(this.preferred, this.fallback) {
    for (final way in [preferred, fallback]) {
      way.peers.listen(_peers.add);
      if (way is ActiveDiscovery) {
        way.departures.listen(_departures.add);
      }
    }
  }

  final Discovery preferred;
  final Discovery fallback;
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  final StreamController<String> _departures = .broadcast();
  Discovery? _active;

  /// The way that runs, once started.
  Discovery? get active => _active;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Stream<String> get departures => _departures.stream;

  @override
  bool get isBlocked => switch (_active) {
    ActiveDiscovery(:final isBlocked) => isBlocked,
    _ => false,
  };

  @override
  Future<void> start(Announce self) async {
    final active = _active;
    if (active != null) {
      return active.start(self);
    }

    try {
      await preferred.start(self);
      _active = preferred;
    } on Object catch (error) {
      printDebug('${preferred.runtimeType} did not start: $error');
      await fallback.start(self);
      _active = fallback;
    }
  }

  @override
  Future<void> announceNow() async => _active?.announceNow();

  @override
  Future<void> scan() async => switch (_active) {
    final ActiveDiscovery way => way.scan(),
    final way? => way.announceNow(),
    null => null,
  };

  /// Stops the running way; the next [start] tries [preferred] again.
  @override
  Future<void> stop() async {
    final active = _active;
    _active = null;
    await active?.stop();
  }
}
