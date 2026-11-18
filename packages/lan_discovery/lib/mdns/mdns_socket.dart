import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:lan_discovery/dns/dns.dart';
import 'package:lan_discovery/net/net.dart';

/// A DNS message that arrived on the mDNS group, and who sent it.
typedef MdnsPacket = ({DnsMessage message, InternetAddress address, int port});

/// What an advertiser or a browser talks through. [MdnsSocket] is the real
/// one; tests link several in memory.
abstract interface class MdnsLink {
  /// Well-formed DNS messages as they arrive.
  Stream<MdnsPacket> get packets;

  /// Whether this link is on the mDNS port itself, so it hears questions
  /// and announcements meant for everyone.
  bool get sharesPort;

  /// Whether the system refused every packet of the last multicast, which
  /// is what a missing local network permission looks like.
  bool get isBlocked;

  /// Sends one message to the group on every interface. [build] gets the
  /// address of the interface the packet leaves from.
  Future<void> multicast(DnsMessage Function(InternetAddress local) build);

  /// Sends [message] to one device.
  void sendTo(DnsMessage message, InternetAddress address, int toPort);

  void close();
}

/// The UDP socket mDNS talks through: bound to port 5353, joined to the
/// group on every interface. IPv4 only.
class MdnsSocket implements MdnsLink {
  MdnsSocket._(this._socket, {required this.sharesPort});

  static const port = 5353;
  static final group = InternetAddress('224.0.0.251');
  static const _hops = 255;

  /// Opens the socket. The system's own mDNS service usually holds the
  /// port, so it is shared. When it can't be, [orAnyPort] takes another
  /// port instead of throwing: enough to ask questions and get the answers
  /// sent straight back, not enough to hear other devices' questions.
  static Future<MdnsSocket> bind({bool orAnyPort = false}) async {
    final (socket, sharesPort) = await _open(orAnyPort);
    final mdns = MdnsSocket._(socket, sharesPort: sharesPort);
    socket
      ..multicastHops = _hops
      ..multicastLoopback = true
      ..listen(mdns._onEvent, onError: mdns._onSocketError);
    if (!sharesPort) {
      return mdns;
    }

    final joined = await LocalInterfaces.joinEverywhere(socket, group);
    if (!joined) {
      mdns._logOnce('mDNS could not join its group');
    }

    return mdns;
  }

  /// Windows shares the port with address reuse alone.
  static Future<(RawDatagramSocket, bool)> _open(bool orAnyPort) async {
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reusePort: true,
      );
      return (socket, true);
    } on Object {
      // Falls through to binding without port reuse.
    }

    try {
      return (
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, port),
        true,
      );
    } on Object {
      if (!orAnyPort) {
        rethrow;
      }
    }

    return (await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0), false);
  }

  final RawDatagramSocket _socket;

  @override
  final bool sharesPort;

  final StreamController<MdnsPacket> _packets = .broadcast();
  final Set<String> _logged = {};
  bool _closed = false;
  bool _blocked = false;

  @override
  Stream<MdnsPacket> get packets => _packets.stream;

  bool get isClosed => _closed;

  @override
  bool get isBlocked => _blocked;

  @override
  Future<void> multicast(
    DnsMessage Function(InternetAddress local) build,
  ) async {
    final addresses = await LocalInterfaces.addresses();
    if (_closed || addresses.isEmpty) {
      return;
    }

    var sent = 0;
    for (final local in addresses) {
      if (!LocalInterfaces.sendMulticastFrom(_socket, local)) {
        continue;
      }

      if (_send(build(local).encode(), group, port)) {
        sent++;
      }
    }

    _blocked = sent == 0;
  }

  @override
  void sendTo(DnsMessage message, InternetAddress address, int toPort) {
    if (_closed) {
      return;
    }

    _send(message.encode(), address, toPort);
  }

  @override
  void close() {
    if (_closed) {
      return;
    }

    _closed = true;
    _socket.close();
    unawaited(_packets.close());
  }

  /// A failed send returns 0 here and reports the reason on the stream.
  bool _send(Uint8List packet, InternetAddress address, int toPort) {
    try {
      return _socket.send(packet, address, toPort) > 0;
    } on Object catch (error) {
      _logOnce('mDNS send failed: ${_describe(error)}');
      return false;
    }
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final datagram = _socket.receive();
    if (datagram == null) {
      return;
    }

    final message = DnsMessage.decode(datagram.data);
    if (message == null) {
      return;
    }

    _packets.add((
      message: message,
      address: datagram.address,
      port: datagram.port,
    ));
  }

  void _onSocketError(Object error) =>
      _logOnce('mDNS socket: ${_describe(error)}');

  String _describe(Object error) => switch (error) {
    SocketException(:final osError?) => osError.message,
    _ => '${error.runtimeType}',
  };

  /// The same failure repeats on every send, so it is said once.
  void _logOnce(String message) {
    if (!_logged.add(message)) {
      return;
    }

    printDebug(message);
  }
}
