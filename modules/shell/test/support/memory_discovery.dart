import 'dart:async';

import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// Discovery over an in-memory bus, so tests don't need multicast.
class MemoryDiscoveryBus {
  final List<_MemoryDiscovery> _members = [];

  Discovery join() {
    final member = _MemoryDiscovery(this);
    _members.add(member);
    return member;
  }
}

class _MemoryDiscovery implements Discovery {
  _MemoryDiscovery(this._bus);

  final MemoryDiscoveryBus _bus;
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  Announce? _self;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start(Announce self) async {
    _self = self;
    await announceNow();
  }

  @override
  Future<void> announceNow() async {
    final announce = _self;
    if (announce == null) {
      return;
    }

    for (final member in _bus._members) {
      if (member != this && member._self != null) {
        member._peers.add(
          DiscoveredPeer(announce: announce, host: '127.0.0.1'),
        );
        _peers.add(
          DiscoveredPeer(announce: member._self ?? announce, host: '127.0.0.1'),
        );
      }
    }
  }

  @override
  Future<void> stop() async => _self = null;
}
