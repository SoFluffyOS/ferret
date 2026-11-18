import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:lan_discovery/dns/dns.dart';
import 'package:lan_discovery/mdns/mdns_responder.dart';
import 'package:lan_discovery/mdns/mdns_service.dart';
import 'package:lan_discovery/mdns/mdns_socket.dart';
import 'package:lan_discovery/net/net.dart';

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
    MdnsLink? socket,
  }) : _responder = MdnsResponder(service),
       _shared = socket;

  static const _firstAnnouncements = [
    Duration.zero,
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];
  static const _minGap = Duration(seconds: 1);

  /// How often the service is announced again unasked, for networks where
  /// questions don't get through. Null announces only at the start and
  /// when asked.
  final Duration? reannounceEvery;

  final MdnsResponder _responder;
  final MdnsLink? _shared;
  final List<Timer> _timers = [];
  MdnsLink? _socket;
  StreamSubscription<MdnsPacket>? _packets;
  DateTime? _lastMulticast;
  Timer? _delayedAnswer;

  bool get isRunning => _socket != null;

  /// Joins the mDNS group and announces the service. Throws a
  /// [SocketException] when the mDNS port can't be shared.
  Future<void> start() async {
    if (_socket != null) {
      return;
    }

    final socket = _shared ?? await MdnsSocket.bind();
    _socket = socket;
    _packets = socket.packets.listen((packet) => unawaited(_onPacket(packet)));

    for (final delay in _firstAnnouncements) {
      _timers.add(Timer(delay, () => unawaited(announce())));
    }

    if (reannounceEvery case final every?) {
      _timers.add(.periodic(every, (_) => unawaited(announce())));
    }
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
    await _packets?.cancel();
    _packets = null;
    await _multicast(socket, goodbye: true);
    _socket = null;
    if (_shared == null) {
      socket.close();
    }
  }

  /// Announces the service right now, such as after the network changed.
  Future<void> announce() async {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    await _multicast(socket, goodbye: false);
  }

  Future<void> _multicast(MdnsLink socket, {required bool goodbye}) {
    _lastMulticast = DateTime.now();
    return socket.multicast(
      (local) => _responder.announcement(local, goodbye: goodbye),
    );
  }

  Future<void> _onPacket(MdnsPacket packet) async {
    final query = packet.message;
    if (query.isResponse || query.questions.isEmpty) {
      return;
    }

    final addresses = await LocalInterfaces.addresses();
    final nearest = _nearest(addresses, packet.address);
    if (nearest == null) {
      return;
    }

    final answer = _responder.answer(query, nearest);
    if (answer == null) {
      return;
    }

    if (packet.port != MdnsSocket.port) {
      _answerDirectly(query, answer, packet);
      return;
    }

    _answerSoon();
  }

  /// One-shot resolvers ask from another port and expect the answer
  /// sent straight back, with their id and question repeated.
  void _answerDirectly(DnsMessage query, DnsMessage answer, MdnsPacket packet) {
    final reply = DnsMessage(
      id: query.id,
      isResponse: true,
      questions: query.questions,
      answers: answer.answers,
      additionals: answer.additionals,
    );
    _socket?.sendTo(reply, packet.address, packet.port);
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
      unawaited(announce());
      return;
    }

    _delayedAnswer = Timer(wait, () {
      _delayedAnswer = null;
      unawaited(announce());
    });
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
}
