import 'dart:async';
import 'dart:io';

import 'package:lan_discovery/lan_discovery.dart';

/// A pretend network: what one link multicasts, every link on the mDNS port
/// hears, as bytes that went through the codec.
class MemoryMdnsNetwork {
  final List<MemoryMdnsLink> _links = [];
  var _nextHost = 10;

  MemoryMdnsLink join({bool sharesPort = true}) {
    final link = MemoryMdnsLink._(
      this,
      InternetAddress('192.168.1.${_nextHost++}'),
      sharesPort: sharesPort,
    );
    _links.add(link);
    return link;
  }

  void _deliver(MemoryMdnsLink from, DnsMessage message, MemoryMdnsLink to) {
    final decoded = DnsMessage.decode(message.encode());
    if (decoded == null || to._closed) {
      return;
    }

    to._packets.add((message: decoded, address: from.address, port: from.port));
  }
}

class MemoryMdnsLink implements MdnsLink {
  MemoryMdnsLink._(this._network, this.address, {required this.sharesPort});

  final MemoryMdnsNetwork _network;
  final InternetAddress address;
  final StreamController<MdnsPacket> _packets = .broadcast();
  final List<DnsMessage> sent = [];
  bool _closed = false;

  @override
  final bool sharesPort;

  int get port => switch (sharesPort) {
    true => MdnsSocket.port,
    false => 50000,
  };

  @override
  bool isBlocked = false;

  @override
  Stream<MdnsPacket> get packets => _packets.stream;

  @override
  Future<void> multicast(
    DnsMessage Function(InternetAddress local) build,
  ) async {
    final message = build(address);
    sent.add(message);
    for (final link in [..._network._links]) {
      if (link.sharesPort) {
        _network._deliver(this, message, link);
      }
    }
  }

  @override
  void sendTo(DnsMessage message, InternetAddress to, int toPort) {
    sent.add(message);
    for (final link in [..._network._links]) {
      if (link.address == to && link.port == toPort) {
        _network._deliver(this, message, link);
      }
    }
  }

  @override
  void close() => _closed = true;
}
