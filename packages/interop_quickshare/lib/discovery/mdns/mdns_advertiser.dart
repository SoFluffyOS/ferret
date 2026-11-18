import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:interop_quickshare/discovery/mdns/dns_message.dart';
import 'package:interop_quickshare/discovery/mdns/mdns_responder.dart';
import 'package:interop_quickshare/discovery/mdns/mdns_service.dart';

/// Announces one service on the local network over multicast DNS and
/// answers questions about it, for as long as it runs.
///
/// It is a small responder, not a full mDNS stack: IPv4 only, and it
/// doesn't probe for name conflicts, so the names it is given must be
/// random enough to be unique.
class MdnsAdvertiser {
  MdnsAdvertiser(
    MdnsService service, {
    this.reannounceEvery = const Duration(seconds: 10),
  }) : _responder = MdnsResponder(service);

  static const port = 5353;
  static final group = InternetAddress('224.0.0.251');
  static const _hops = 255;
  static const _firstAnnouncements = [
    Duration.zero,
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];
  static const _minGap = Duration(seconds: 1);

  /// How often the service is announced again unasked, for networks
  /// where questions don't get through.
  final Duration reannounceEvery;

  final MdnsResponder _responder;
  final List<Timer> _timers = [];
  RawDatagramSocket? _socket;
  DateTime? _lastMulticast;
  Timer? _delayedAnswer;

  bool get isRunning => _socket != null;

  /// Joins the mDNS group and announces the service. Throws a
  /// [SocketException] when the mDNS port can't be shared.
  Future<void> start() async {
    if (_socket != null) {
      return;
    }

    final socket = await _bind();
    socket
      ..multicastHops = _hops
      ..multicastLoopback = true
      ..listen(_onEvent, onError: _onSocketError);
    await _joinGroup(socket);
    _socket = socket;

    for (final delay in _firstAnnouncements) {
      _timers.add(Timer(delay, () => unawaited(_announce())));
    }

    _timers.add(.periodic(reannounceEvery, (_) => unawaited(_announce())));
  }

  /// Tells the network the service is gone, then leaves.
  Future<void> stop() async {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    for (final timer in _timers) {
      timer.cancel();
    }

    _timers.clear();
    _delayedAnswer?.cancel();
    _delayedAnswer = null;
    await _announce(goodbye: true);
    _socket = null;
    socket.close();
  }

  Future<void> _announce({bool goodbye = false}) async {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    _lastMulticast = DateTime.now();
    for (final address in await _localAddresses()) {
      final packet = _responder
          .announcement(address, goodbye: goodbye)
          .encode();
      _multicastOn(socket, address, packet);
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

    unawaited(_onPacket(datagram));
  }

  Future<void> _onPacket(Datagram datagram) async {
    final query = DnsMessage.decode(datagram.data);
    if (query == null || query.isResponse || query.questions.isEmpty) {
      return;
    }

    final addresses = await _localAddresses();
    final nearest = _nearest(addresses, datagram.address);
    if (nearest == null || _responder.answer(query, nearest) == null) {
      return;
    }

    if (datagram.port != port) {
      _answerDirectly(query, nearest, datagram);
      return;
    }

    _answerSoon();
  }

  /// One-shot resolvers ask from another port and expect the answer
  /// sent straight back, with their id and question repeated.
  void _answerDirectly(
    DnsMessage query,
    InternetAddress local,
    Datagram datagram,
  ) {
    final answer = _responder.answer(query, local);
    if (answer == null) {
      return;
    }

    final packet = DnsMessage(
      id: query.id,
      isResponse: true,
      questions: query.questions,
      answers: answer.answers,
      additionals: answer.additionals,
    ).encode();
    _send(packet, datagram.address, datagram.port);
  }

  /// Answers everyone at once with the whole service, at most once per
  /// second however many devices ask.
  void _answerSoon() {
    if (_delayedAnswer != null) {
      return;
    }

    final last = _lastMulticast;
    final wait = switch (last) {
      null => Duration.zero,
      _ => _minGap - DateTime.now().difference(last),
    };
    if (wait <= Duration.zero) {
      unawaited(_announce());
      return;
    }

    _delayedAnswer = Timer(wait, () {
      _delayedAnswer = null;
      unawaited(_announce());
    });
  }

  /// Sends on the interface that owns [local], so every network this
  /// device is on hears the address that works there.
  void _multicastOn(
    RawDatagramSocket socket,
    InternetAddress local,
    Uint8List packet,
  ) {
    try {
      socket.setRawOption(
        RawSocketOption(
          RawSocketOption.levelIPv4,
          RawSocketOption.IPv4MulticastInterface,
          local.rawAddress,
        ),
      );
    } on Object {
      return;
    }

    _send(packet, group, port);
  }

  void _send(Uint8List packet, InternetAddress address, int toPort) {
    try {
      _socket?.send(packet, address, toPort);
    } on SocketException catch (error) {
      printDebug('mDNS send failed: ${error.osError?.message}');
    }
  }

  /// The local address that shares the most leading bits with [remote],
  /// which is the one on its network.
  InternetAddress? _nearest(
    List<InternetAddress> addresses,
    InternetAddress remote,
  ) {
    InternetAddress? best;
    var bestBits = -1;
    for (final address in addresses) {
      final bits = _commonBits(address.rawAddress, remote.rawAddress);
      if (bits > bestBits) {
        best = address;
        bestBits = bits;
      }
    }

    return best;
  }

  int _commonBits(Uint8List first, Uint8List second) {
    if (first.length != second.length) {
      return 0;
    }

    var bits = 0;
    for (var index = 0; index < first.length; index++) {
      final difference = first[index] ^ second[index];
      if (difference == 0) {
        bits += 8;
        continue;
      }

      return bits + 8 - difference.bitLength;
    }

    return bits;
  }

  Future<List<InternetAddress>> _localAddresses() async {
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

  /// The system's own mDNS service usually holds the port already, so it
  /// has to be shared. Windows shares it with address reuse alone.
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
      printWarning('mDNS could not join its group', error);
    }
  }

  /// Dart reports failed datagram sends here instead of throwing.
  void _onSocketError(Object error) {
    final detail = switch (error) {
      SocketException(:final osError?) => osError.message,
      _ => '${error.runtimeType}',
    };
    printDebug('mDNS socket: $detail');
  }
}
