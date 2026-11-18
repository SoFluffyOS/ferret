import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:lan_discovery/lan_discovery.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/discovery/discovered_peer.dart';

/// Finds devices with UDP multicast on the local network.
///
/// Each packet is `FRT` + a version byte + an `Announce`. Announces carry no
/// secrets; trust comes from the Noise handshake that follows.
class MulticastDiscovery implements ActiveDiscovery {
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

  static const _scanWait = Duration(seconds: 1);
  static final _everyone = InternetAddress('255.255.255.255');

  final StreamController<DiscoveredPeer> _peers = .broadcast();
  final StreamController<String> _departures = .broadcast();
  final Set<String> _logged = {};
  bool _blocked = false;
  RawDatagramSocket? _socket;
  Timer? _timer;
  Announce? _self;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  /// Announces don't expire one by one; the engine forgets quiet devices.
  @override
  Stream<String> get departures => _departures.stream;

  @override
  bool get isBlocked => _blocked;

  /// An announce is also a question: everyone who hears it answers.
  @override
  Future<void> scan() async {
    await announceNow();
    await Future<void>.delayed(_scanWait);
  }

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
    var sent = 0;
    for (final address in await LocalInterfaces.addresses()) {
      if (!LocalInterfaces.sendMulticastFrom(socket, address)) {
        continue;
      }

      if (_send(socket, packet, group)) {
        sent++;
      }
    }

    if (_send(socket, packet, _everyone)) {
      sent++;
    }

    _blocked = sent == 0;
  }

  /// A failed send returns 0 and reports the reason on the socket's stream.
  bool _send(
    RawDatagramSocket socket,
    List<int> packet,
    InternetAddress address,
  ) {
    try {
      return socket.send(packet, address, port) > 0;
    } on SocketException catch (error) {
      _logOnce('Announce failed: ${error.osError?.message}');
      return false;
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
    final joined = await LocalInterfaces.joinEverywhere(socket, group);
    if (!joined) {
      _logOnce('Multicast discovery could not join ${group.address}');
    }
  }

  /// Dart reports failed datagram sends here rather than throwing. The
  /// address in the error is the one this socket is bound to, not where
  /// the packet was going. "No route to host" on macOS and iOS means the
  /// local network permission is off; it repeats on every announce, so it
  /// is said once.
  void _onSocketError(Object error) {
    final detail = switch (error) {
      SocketException(:final osError?) => osError.message,
      _ => '${error.runtimeType}',
    };
    _logOnce('Discovery can\'t send on this network: $detail');
  }

  void _logOnce(String message) {
    if (!_logged.add(message)) {
      return;
    }

    printDebug(message);
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
