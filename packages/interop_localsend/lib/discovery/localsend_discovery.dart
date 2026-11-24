import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:interop_localsend/discovery/localsend_announcement.dart';
import 'package:interop_localsend/models/models.dart';
import 'package:interop_localsend/security/security.dart';

/// Finds LocalSend members with UDP multicast (protocol section 3.1).
///
/// It only listens and answers while started, and only announces when
/// asked to, so nothing is sent on a schedule.
class LocalSendDiscovery {
  LocalSendDiscovery({
    required this.self,
    this.shouldAnswer = _never,
    this.register,
    this.port = LocalSendDefaults.port,
    this.peerLifetime = const Duration(minutes: 3),
    InternetAddress? group,
    DateTime Function()? clock,
  }) : group = group ?? InternetAddress(LocalSendDefaults.multicastGroup),
       _clock = clock ?? DateTime.now;

  /// This device's description, or null while it has none to give.
  final LocalSendInfo? Function() self;

  /// Whether to answer other members' announcements. Answering makes this
  /// device show up in their lists, so it should be true only while it
  /// accepts files.
  final bool Function() shouldAnswer;

  /// Answers an announcement over HTTP (`/register`). When it is missing
  /// or returns false, the answer goes out over multicast instead.
  final Future<bool> Function(LocalSendPeer peer)? register;

  final InternetAddress group;
  final int port;

  /// How long a member stays listed after it was last heard.
  final Duration peerLifetime;

  final DateTime Function() _clock;
  final Map<String, LocalSendPeer> _peers = {};
  final StreamController<List<LocalSendPeer>> _changes = .broadcast();
  RawDatagramSocket? _socket;

  bool get isStarted => _socket != null;

  /// Members heard recently, in the order they were found.
  List<LocalSendPeer> get peers {
    final oldest = _clock().subtract(peerLifetime);
    _peers.removeWhere((_, peer) => peer.lastSeen.isBefore(oldest));
    return List.unmodifiable(_peers.values);
  }

  /// The list of members after each change.
  Stream<List<LocalSendPeer>> get changes => _changes.stream;

  /// Joins the multicast group and listens. Throws a [SocketException]
  /// when the port can't be bound.
  Future<void> start() async {
    if (_socket != null) {
      return;
    }

    final socket = await _bind();
    socket
      ..multicastLoopback = false
      ..listen(_onEvent, onError: _onSocketError);
    await _joinGroup(socket);
    _socket = socket;
  }

  Future<void> stop() async {
    _socket?.close();
    _socket = null;
  }

  Future<void> dispose() async {
    await stop();
    await _changes.close();
  }

  /// Asks every member on the network to answer.
  Future<void> announce() => _send(announce: true);

  /// Lists a member found another way, such as through `/register` or an
  /// address scan.
  void add(LocalSendInfo info, InternetAddress address) {
    final own = self();
    if (own != null && Fingerprints.same(own.fingerprint, info.fingerprint)) {
      return;
    }

    _peers[info.fingerprint.toLowerCase()] = LocalSendPeer(
      info: info,
      address: address,
      lastSeen: _clock(),
    );
    _emit();
  }

  /// Forgets every member, such as before looking again.
  void clear() {
    if (_peers.isEmpty) {
      return;
    }

    _peers.clear();
    _emit();
  }

  /// Handles one packet from [address]. Public so the protocol can be
  /// tested without a network.
  void onPacket(List<int> packet, InternetAddress address) {
    final announcement = LocalSendAnnouncement.decode(packet);
    final own = self();
    if (announcement == null || own == null) {
      return;
    }

    final info = announcement.info;
    if (Fingerprints.same(info.fingerprint, own.fingerprint)) {
      return;
    }

    add(info, address);
    if (!announcement.announce || !shouldAnswer()) {
      return;
    }

    final peer = _peers[info.fingerprint.toLowerCase()];
    if (peer != null) {
      unawaited(_answer(peer));
    }
  }

  Future<void> _answer(LocalSendPeer peer) async {
    final answered = await _registerQuietly(peer);
    if (answered) {
      return;
    }

    await _send(announce: false);
  }

  Future<bool> _registerQuietly(LocalSendPeer peer) async {
    final register = this.register;
    if (register == null) {
      return false;
    }

    try {
      return await register(peer);
    } on Object {
      return false;
    }
  }

  Future<void> _send({required bool announce}) async {
    final (socket, own) = (_socket, self());
    if (socket == null || own == null) {
      return;
    }

    final packet = LocalSendAnnouncement(
      info: own,
      announce: announce,
    ).encode();
    final interfaces = await _interfaces();
    for (final interface in interfaces) {
      _sendOn(socket, packet, interface);
    }

    if (interfaces.isEmpty) {
      _sendTo(socket, packet);
    }
  }

  /// Sends on one interface, so multicast works without a default route,
  /// such as with a VPN or several networks at once.
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

    _sendTo(socket, packet);
  }

  void _sendTo(RawDatagramSocket socket, List<int> packet) {
    try {
      socket.send(packet, group, port);
    } on SocketException catch (error) {
      printDebug('LocalSend announce failed: ${error.osError?.message}');
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

  Future<RawDatagramSocket> _bind() async {
    try {
      return await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reusePort: !Platform.isWindows,
      );
    } on Object {
      return RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    }
  }

  Future<void> _joinGroup(RawDatagramSocket socket) async {
    var joined = false;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        try {
          socket.joinMulticast(group, interface);
          joined = true;
        } on Object {
          continue;
        }
      }
    } on Object {
      joined = false;
    }

    if (joined) {
      return;
    }

    try {
      socket.joinMulticast(group);
    } on Object catch (error) {
      printWarning(
        'LocalSend discovery could not join ${group.address}',
        error,
      );
    }
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final datagram = _socket?.receive();
    if (datagram == null) {
      return;
    }

    onPacket(datagram.data, datagram.address);
  }

  /// Dart reports failed datagram sends here instead of throwing.
  void _onSocketError(Object error) {
    printDebug('LocalSend discovery socket: ${error.runtimeType}');
  }

  void _emit() {
    if (_changes.isClosed) {
      return;
    }

    _changes.add(peers);
  }

  static bool _never() => false;
}
