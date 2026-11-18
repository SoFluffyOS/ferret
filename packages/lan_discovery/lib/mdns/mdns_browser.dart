import 'dart:async';
import 'dart:io';

import 'package:lan_discovery/dns/dns.dart';
import 'package:lan_discovery/mdns/mdns_instance.dart';
import 'package:lan_discovery/mdns/mdns_socket.dart';

/// Finds the instances of one service type on the local network: asks who
/// offers it, collects the answers, and forgets instances that said goodbye
/// or whose records ran out.
class MdnsBrowser {
  MdnsBrowser(
    this.type, {
    this.rescanEvery = const Duration(seconds: 30),
    this.collectFor = const Duration(seconds: 2),
    this.ignore,
    MdnsLink? socket,
  }) : _shared = socket;

  /// The service type, such as `_ipp._tcp`.
  final String type;

  /// How often to ask again while nobody calls [scan].
  final Duration rescanEvery;

  /// How long one scan waits for answers.
  final Duration collectFor;

  /// An instance label to leave out: this device's own.
  final String? ignore;

  final MdnsLink? _shared;
  final Map<String, _Found> _found = {};
  final StreamController<MdnsInstance> _appeared = .broadcast();
  final StreamController<String> _left = .broadcast();
  final StreamController<void> _scans = .broadcast();
  MdnsLink? _socket;
  StreamSubscription<MdnsPacket>? _packets;
  Timer? _rescan;
  Timer? _expiry;
  Future<void>? _scanning;

  /// Instances as they are found or change. One that stays is not repeated.
  Stream<MdnsInstance> get appeared => _appeared.stream;

  /// The labels of instances that left.
  Stream<String> get left => _left.stream;

  /// Fires after each scan, asked for or on the timer, when [instances] is
  /// as fresh as it gets.
  Stream<void> get scans => _scans.stream;

  /// Every instance known right now.
  List<MdnsInstance> get instances => [
    for (final found in _found.values) ?found.instance,
  ];

  bool get isRunning => _socket != null;

  List<String> get _typeName => [...type.split('.'), 'local'];

  /// Starts listening and scans once. Throws a [SocketException] when no
  /// UDP socket can be opened at all.
  Future<void> start() async {
    if (_socket != null) {
      return;
    }

    final socket = _shared ?? await MdnsSocket.bind(orAnyPort: true);
    _socket = socket;
    _packets = socket.packets.listen(_onPacket);
    _rescan = .periodic(rescanEvery, (_) => unawaited(scan()));
    unawaited(scan());
  }

  Future<void> stop() async {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    _rescan?.cancel();
    _rescan = null;
    _expiry?.cancel();
    _expiry = null;
    await _packets?.cancel();
    _packets = null;
    _socket = null;
    _found.clear();
    if (_shared == null) {
      socket.close();
    }
  }

  /// Asks the network who offers the service and waits [collectFor] for
  /// the answers. Scans asked for while one runs join it.
  Future<void> scan() {
    if (_scanning case final running?) {
      return running;
    }

    final run = _scanOnce().whenComplete(() => _scanning = null);
    _scanning = run;
    return run;
  }

  /// Asks twice, because a lone UDP question is easily lost on Wi-Fi.
  Future<void> _scanOnce() async {
    await _ask(_typeName, DnsType.ptr);
    await Future<void>.delayed(collectFor ~/ 2);
    await _ask(_typeName, DnsType.ptr);
    await Future<void>.delayed(collectFor ~/ 2);
    _dropExpired();
    if (_socket != null) {
      _scans.add(null);
    }
  }

  /// From the mDNS port everyone hears the answer. From any other port the
  /// answer has to come straight back, which the top bit asks for.
  Future<void> _ask(List<String> name, int questionType) async {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    final question = DnsQuestion(
      name: name,
      type: questionType,
      wantsUnicast: !socket.sharesPort,
    );
    await socket.multicast((_) => DnsMessage(questions: [question]));
  }

  void _onPacket(MdnsPacket packet) {
    if (!packet.message.isResponse) {
      return;
    }

    final touched = <String>{};
    final records = [...packet.message.answers, ...packet.message.additionals];
    for (final record in records) {
      final label = _read(record);
      if (label != null) {
        touched.add(label);
      }
    }

    for (final label in touched) {
      _settle(label, packet.address);
    }

    _scheduleExpiry();
  }

  /// Takes what [record] says about an instance of this service. Returns
  /// the instance's key, or null when the record is about something else.
  String? _read(DnsRecord record) {
    final label = _instanceOf(record);
    if (label == null || label.toLowerCase() == ignore?.toLowerCase()) {
      return null;
    }

    final key = label.toLowerCase();
    if (record.ttl == 0) {
      _forget(key);
      return null;
    }

    final found = _found.putIfAbsent(key, () => _Found(label));
    switch (record.type) {
      case DnsType.srv:
        found
          ..port = record.port
          ..expires = DateTime.now().add(Duration(seconds: record.ttl));
      case DnsType.txt:
        found.txt = record.txtEntries;
      default:
        break;
    }

    return key;
  }

  /// The instance label a PTR, SRV or TXT record of this type is about.
  String? _instanceOf(DnsRecord record) {
    final typeName = _typeName;
    if (record.type == DnsType.ptr) {
      final target = record.target;
      if (target == null || !DnsWire.sameName(record.name, typeName)) {
        return null;
      }

      return _labelOf(target);
    }

    if (record.type != DnsType.srv && record.type != DnsType.txt) {
      return null;
    }

    return _labelOf(record.name);
  }

  String? _labelOf(List<String> instanceName) {
    final typeName = _typeName;
    if (instanceName.length != typeName.length + 1 ||
        !DnsWire.sameName(instanceName.sublist(1), typeName)) {
      return null;
    }

    return instanceName.first;
  }

  /// Announces the instance once its port is known, and asks for the
  /// details when an answer named it without them.
  void _settle(String key, InternetAddress address) {
    final found = _found[key];
    if (found == null) {
      return;
    }

    if (found.port == 0) {
      if (!found.asked) {
        found.asked = true;
        unawaited(_ask([found.label, ..._typeName], DnsType.any));
      }

      return;
    }

    final previous = found.instance;
    final instance = MdnsInstance(
      name: found.label,
      address: address,
      port: found.port,
      txt: found.txt,
    );
    found.instance = instance;
    if (previous != null && _same(previous, instance)) {
      return;
    }

    _appeared.add(instance);
  }

  bool _same(MdnsInstance first, MdnsInstance second) {
    if (first.address != second.address ||
        first.port != second.port ||
        first.txt.length != second.txt.length) {
      return false;
    }

    for (final MapEntry(:key, :value) in first.txt.entries) {
      if (second.txt[key] != value) {
        return false;
      }
    }

    return true;
  }

  void _forget(String key) {
    final found = _found.remove(key);
    if (found?.instance == null) {
      return;
    }

    _left.add(found?.label ?? key);
  }

  void _dropExpired() {
    final now = DateTime.now();
    final expired = [
      for (final MapEntry(:key, :value) in _found.entries)
        if (value.expires case final expires? when expires.isBefore(now)) key,
    ];
    for (final key in expired) {
      _forget(key);
    }
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    DateTime? next;
    for (final found in _found.values) {
      final expires = found.expires;
      if (expires == null) {
        continue;
      }

      if (next == null || expires.isBefore(next)) {
        next = expires;
      }
    }

    if (next == null) {
      return;
    }

    final wait = next.difference(DateTime.now()) + const Duration(seconds: 1);
    _expiry = Timer(wait, () {
      _dropExpired();
      _scheduleExpiry();
    });
  }
}

class _Found {
  _Found(this.label);

  final String label;
  int port = 0;
  Map<String, String> txt = const {};
  DateTime? expires;
  bool asked = false;
  MdnsInstance? instance;
}
