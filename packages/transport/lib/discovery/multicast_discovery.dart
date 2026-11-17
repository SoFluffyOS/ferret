import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/discovery/discovered_peer.dart';

/// Finds devices with UDP multicast on the local network.
///
/// Each packet is `FRT` + a version byte + an `Announce`. Announces carry no
/// secrets; trust comes from the Noise handshake that follows.
class MulticastDiscovery implements Discovery {
  MulticastDiscovery({
    InternetAddress? group,
    this.port = defaultPort,
    this.interval = const Duration(seconds: 30),
  }) : group = group ?? InternetAddress(defaultGroup);

  static const defaultGroup = '239.255.70.84';
  static const defaultPort = 47641;
  static const _magic = [0x46, 0x52, 0x54, 0x01];

  final InternetAddress group;
  final int port;
  final Duration interval;

  final StreamController<DiscoveredPeer> _peers = .broadcast();
  RawDatagramSocket? _socket;
  Timer? _timer;
  Announce? _self;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start(Announce self) async {
    _self = self;
    if (_socket != null) {
      return announceNow();
    }

    final socket = await _bind();
    socket
      ..multicastLoopback = false
      ..broadcastEnabled = true
      ..listen(_onEvent, onError: _onSocketError);
    await _joinGroup(socket);
    _socket = socket;

    _timer = .periodic(interval, (_) => unawaited(announceNow()));
    await announceNow();
  }

  @override
  Future<void> announceNow() async {
    final (socket, self) = (_socket, _self);
    if (socket == null || self == null) {
      return;
    }

    final packet = encodeAnnounce(self.deepCopy()..reply = false);
    final interfaces = await _interfaces();
    for (final address in interfaces) {
      _sendOn(socket, packet, address);
    }

    _send(socket, packet, InternetAddress('255.255.255.255'));
  }

  /// Sends on one interface, so multicast works without a default route
  /// (macOS with a VPN, or several networks at once).
  void _sendOn(
    RawDatagramSocket socket,
    List<int> packet,
    InternetAddress interface,
  ) {
    try {
      socket.setRawOption(
        RawSocketOption(
          RawSocketOption.levelIPv4,
          RawSocketOption.IPv4MulticastInterface,
          interface.rawAddress,
        ),
      );
    } on Object {
      return;
    }

    _send(socket, packet, group);
  }

  void _send(
    RawDatagramSocket socket,
    List<int> packet,
    InternetAddress address,
  ) {
    try {
      socket.send(packet, address, port);
    } on SocketException catch (error) {
      printDebug(
        'Announce to ${address.address} failed: ${error.osError?.message}',
      );
    }
  }

  Future<List<InternetAddress>> _interfaces() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      return [
        for (final interface in interfaces)
          for (final address in interface.addresses)
            if (!address.isLoopback && !address.isLinkLocal) address,
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _socket?.close();
    _socket = null;
  }

  Future<RawDatagramSocket> _bind() async {
    try {
      return await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reusePort: true,
      );
    } on Object {
      return RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    }
  }

  Future<void> _joinGroup(RawDatagramSocket socket) async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    var joined = false;
    for (final interface in interfaces) {
      try {
        socket.joinMulticast(group, interface);
        joined = true;
      } on SocketException {
        continue;
      }
    }

    if (joined) {
      return;
    }

    try {
      socket.joinMulticast(group);
    } on SocketException catch (error) {
      printWarning('Multicast discovery could not join $group', error);
    }
  }

  /// Dart reports failed datagram sends here rather than throwing, such as
  /// "no route to host" on an interface without multicast.
  void _onSocketError(Object error) {
    printDebug('Discovery socket: $error');
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final datagram = _socket?.receive();
    if (datagram == null) {
      return;
    }

    final announce = decodeAnnounce(datagram.data);
    final self = _self;
    if (announce == null ||
        self == null ||
        announce.deviceId == self.deviceId) {
      return;
    }

    _peers.add(
      DiscoveredPeer(announce: announce, host: datagram.address.address),
    );
    if (!announce.reply) {
      _socket?.send(
        encodeAnnounce(self.deepCopy()..reply = true),
        datagram.address,
        port,
      );
    }
  }
}

/// `FRT` + version + the announce.
Uint8List encodeAnnounce(Announce announce) => Uint8List.fromList([
  ...MulticastDiscovery._magic,
  ...announce.writeToBuffer(),
]);

/// The announce in [packet], or null when it isn't a Ferret announce.
Announce? decodeAnnounce(List<int> packet) {
  const magic = MulticastDiscovery._magic;
  if (packet.length <= magic.length) {
    return null;
  }

  for (var i = 0; i < magic.length; i++) {
    if (packet[i] != magic[i]) {
      return null;
    }
  }

  try {
    return Announce.fromBuffer(packet.sublist(magic.length));
  } on Object {
    return null;
  }
}
