import 'dart:async';

import 'package:core/core.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/discovery/discovered_peer.dart';
import 'package:transport/discovery/mdns_discovery.dart';
import 'package:transport/discovery/multicast_discovery.dart';

/// Looks for devices in several ways at once, so one that a network blocks
/// doesn't hide them. A way that can't start is left out.
class CombinedDiscovery
    implements ActiveDiscovery, QuietDiscovery, PacedDiscovery {
  CombinedDiscovery(this._ways);

  /// Ferret's own multicast announce and DNS-SD, side by side.
  factory CombinedDiscovery.standard() =>
      CombinedDiscovery([MulticastDiscovery(), MdnsDiscovery()]);

  final List<Discovery> _ways;
  final Set<Discovery> _failed = {};
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  final StreamController<String> _departures = .broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _announcing = true;
  bool _relaxed = false;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Stream<String> get departures => _departures.stream;

  /// Blocked only when no way got anything out.
  @override
  bool get isBlocked {
    final active = _ways.whereType<ActiveDiscovery>();
    return active.isNotEmpty && active.every((way) => way.isBlocked);
  }

  @override
  bool get isAnnouncing => _announcing;

  @override
  Future<void> setAnnouncing(bool announcing) async {
    _announcing = announcing;
    await Future.wait([
      for (final way in _ways)
        if (way is QuietDiscovery)
          _quietly(() => way.setAnnouncing(announcing)),
    ]);
  }

  @override
  bool get isRelaxed => _relaxed;

  @override
  Future<void> setRelaxed(bool relaxed) async {
    _relaxed = relaxed;
    await Future.wait([
      for (final way in _ways)
        if (way is PacedDiscovery) _quietly(() => way.setRelaxed(relaxed)),
    ]);
  }

  @override
  Future<void> start(Announce self) async {
    if (_subscriptions.isEmpty) {
      for (final way in _ways) {
        _subscriptions.add(way.peers.listen(_peers.add));
        if (way is ActiveDiscovery) {
          _subscriptions.add(way.departures.listen(_departures.add));
        }
      }
    }

    for (final way in _ways) {
      try {
        await way.start(self);
        _failed.remove(way);
      } on Object catch (error) {
        if (_failed.add(way)) {
          printDebug('${way.runtimeType} did not start: $error');
        }
      }
    }
  }

  @override
  Future<void> announceNow() =>
      Future.wait([for (final way in _ways) _quietly(way.announceNow)]);

  @override
  Future<void> scan() => Future.wait([
    for (final way in _ways)
      _quietly(switch (way) {
        ActiveDiscovery() => way.scan,
        _ => way.announceNow,
      }),
  ]);

  @override
  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();
    await Future.wait([for (final way in _ways) _quietly(way.stop)]);
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      printDebug('Discovery: $error');
    }
  }
}
