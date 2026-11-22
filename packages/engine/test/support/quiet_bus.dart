import 'dart:async';

import 'package:protocol/protocol.dart';
import 'package:transport/transport.dart';

/// Devices on one network: an announce reaches every other member, and a
/// member that announces answers it with its own.
class QuietBus {
  final List<QuietMember> members = [];

  QuietMember join() {
    final member = QuietMember(this);
    members.add(member);
    return member;
  }
}

class QuietMember
    implements QuietDiscovery, PacedDiscovery, ListeningDiscovery {
  QuietMember(this.bus);

  final QuietBus bus;
  final StreamController<DiscoveredPeer> _peers = .broadcast();
  final List<Announce> announced = [];
  Announce? self;
  bool _announcing = true;
  bool _relaxed = false;
  bool _listening = true;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  bool get isListening => _listening;

  @override
  Future<void> setListening(bool listening) async => _listening = listening;

  @override
  bool get isRelaxed => _relaxed;

  @override
  Future<void> setRelaxed(bool relaxed) async {
    _relaxed = relaxed;
    if (!relaxed) {
      await announceNow();
    }
  }

  @override
  bool get isAnnouncing => _announcing;

  @override
  Future<void> setAnnouncing(bool announcing) async {
    _announcing = announcing;
    if (announcing) {
      await announceNow();
    }
  }

  @override
  Future<void> start(Announce self) async {
    this.self = self;
    await announceNow();
  }

  /// Announces, or only asks while quiet: members that announce answer.
  @override
  Future<void> announceNow() async {
    final mine = self;
    if (mine == null) {
      return;
    }

    if (_announcing) {
      announced.add(mine);
    }

    for (final member in bus.members) {
      if (member == this) {
        continue;
      }

      if (_announcing) {
        member._peers.add(DiscoveredPeer(announce: mine, host: '127.0.0.1'));
      }

      if ((member.self, member._announcing) case (final other?, true)) {
        _peers.add(DiscoveredPeer(announce: other, host: '127.0.0.1'));
      }
    }
  }

  @override
  Future<void> stop() async => self = null;
}
