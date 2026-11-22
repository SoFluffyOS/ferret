import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:lan_discovery/lan_discovery.dart';
import 'package:protocol/protocol.dart';
import 'package:transport/discovery/announce_pacer.dart';
import 'package:transport/discovery/discovered_peer.dart';

/// Finds devices with UDP multicast on the local network.
///
/// Each packet is `FRT` + a version byte + an `Announce`. Announces carry no
/// secrets; trust comes from the Noise handshake that follows.
///
/// While it isn't announcing, it sends only `FRT` + 2, a question with
/// nothing about this device in it: devices that announce answer it, and
/// older versions ignore it.
class MulticastDiscovery
    implements ActiveDiscovery, QuietDiscovery, PacedDiscovery {
  MulticastDiscovery({
    InternetAddress? group,
    this.port = defaultPort,
    this.interval = const Duration(seconds: 30),
    this.relaxedInterval = const Duration(minutes: 5),
  }) : group = group ?? InternetAddress(defaultGroup),
       _pacer = AnnouncePacer(
         interval: interval,
         relaxedInterval: relaxedInterval,
       );

  static const defaultGroup = '239.255.70.84';
  static const defaultPort = 47641;
  static const _magic = [0x46, 0x52, 0x54, 0x01];
  static const question = [0x46, 0x52, 0x54, 0x02];

  final InternetAddress group;
  final int port;
  final Duration interval;

  /// How often it announces while nothing is left to find. Questions and
  /// announces from others are answered at once either way.
  final Duration relaxedInterval;

  static const _scanWait = Duration(seconds: 1);
  static final _everyone = InternetAddress('255.255.255.255');

  final StreamController<DiscoveredPeer> _peers = .broadcast();
  final StreamController<String> _departures = .broadcast();
  final Set<String> _logged = {};
  bool _blocked = false;
  bool _announcing = true;
  RawDatagramSocket? _socket;
  final AnnouncePacer _pacer;
  final RepeatGate _answered = .new();
  final RepeatGate _passedOn = .new();
  Announce? _self;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  /// Announces don't expire one by one; the engine forgets quiet devices.
  @override
  Stream<String> get departures => _departures.stream;

  @override
  bool get isBlocked => _blocked;

  @override
  bool get isAnnouncing => _announcing;

  @override
  bool get isRelaxed => _pacer.isRelaxed;

  @override
  Future<void> setRelaxed(bool relaxed) async => _pacer.setRelaxed(relaxed);

  @override
  Future<void> setAnnouncing(bool announcing) async {
    if (announcing == _announcing) {
      return;
    }

    _announcing = announcing;
    if (announcing) {
      await announceNow();
    }
  }

  /// An announce is also a question: everyone who hears it answers. While
  /// quiet, the question goes alone.
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

    _pacer.start(() => unawaited(announceNow()));
    await announceNow();
  }

  /// Announces this device, or only asks who is there while it's quiet.
  @override
  Future<void> announceNow() async {
    final (socket, self) = (_socket, _self);
    if (socket == null || self == null) {
      return;
    }

    final packet = switch (_announcing) {
      true => encodeAnnounce(self.deepCopy()..reply = false),
      false => question,
    };
    var sent = 0;
    final addresses = await LocalInterfaces.addresses();
    for (final address in addresses) {
      if (!LocalInterfaces.sendMulticastFrom(socket, address)) {
        continue;
      }

      if (_send(socket, packet, group)) {
        sent++;
      }
    }

    for (final target in broadcastTargets(addresses)) {
      if (_send(socket, packet, target)) {
        sent++;
      }
    }

    _blocked = sent == 0;
  }

  /// Where an announce is broadcast besides the multicast group: each
  /// network's own broadcast address, which reaches routers that drop
  /// multicast and goes out of every interface. macOS refuses the
  /// everyone address (255.255.255.255) with "no route to host" when it
  /// has no default route for it, so that one is only the last resort.
  static List<InternetAddress> broadcastTargets(
    List<InternetAddress> addresses,
  ) {
    final broadcasts = [
      for (final address in addresses)
        ?LocalInterfaces.subnetBroadcast(address),
    ];
    final targets = {
      for (final target in broadcasts) target.address: target,
    };
    if (targets.isEmpty) {
      return [_everyone];
    }

    return [...targets.values];
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
    _pacer.stop();
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

    final self = _self;
    if (isQuestion(datagram.data)) {
      if (self != null &&
          _announcing &&
          _answered.pass('? ${datagram.address.address}')) {
        _answer(self, datagram.address);
      }

      return;
    }

    final announce = decodeAnnounce(datagram.data);
    if (announce == null ||
        self == null ||
        announce.deviceId == self.deviceId) {
      return;
    }

    final host = datagram.address.address;
    final said = announce.deepCopy()..reply = false;
    if (_passedOn.pass('$host ${said.writeToBuffer().join(',')}')) {
      _peers.add(DiscoveredPeer(announce: announce, host: host));
    }

    if (!announce.reply &&
        _announcing &&
        _answered.pass('${announce.deviceId} $host')) {
      _answer(self, datagram.address);
    }
  }

  /// Once per asker within a moment: its announce arrives by multicast and
  /// by broadcast.
  void _answer(Announce self, InternetAddress to) {
    _socket?.send(encodeAnnounce(self.deepCopy()..reply = true), to, port);
  }
}

/// Whether [packet] is a question from a device that doesn't announce.
bool isQuestion(List<int> packet) {
  const question = MulticastDiscovery.question;
  if (packet.length != question.length) {
    return false;
  }

  for (var i = 0; i < question.length; i++) {
    if (packet[i] != question[i]) {
      return false;
    }
  }

  return true;
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
