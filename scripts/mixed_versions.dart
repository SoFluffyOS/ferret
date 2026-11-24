// Drives an older and a newer Ferret against each other on loopback. Run by
// scripts/mixed_versions.sh; see there. Prints each check and exits 1 when
// one fails.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<void> main(List<String> args) async {
  final [oldRepo, newRepo, work] = args;
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final peers = <String, _Peer>{};
  final arrived = StreamController<_Peer>.broadcast();
  server.listen((socket) {
    final peer = _Peer(socket);
    peer.ready.then((_) {
      peers[peer.role] = peer;
      arrived.add(peer);
    });
  });

  final processes = <Process>[];
  Future<_Peer> start(String role, String repo) async {
    final home = '$work/$role';
    await Directory(home).create(recursive: true);
    final waiting = arrived.stream.firstWhere((peer) => peer.role == role);
    // mixed_versions.sh passes the Flutter command it uses (fvm or not).
    final flutter = (Platform.environment['FERRET_FLUTTER'] ?? 'flutter').split(' ');
    final process = await Process.start(
      flutter.first,
      [...flutter.skip(1), 'test', 'test/mixed/mixed_peer_test.dart'],
      workingDirectory: '$repo/apps/ferret',
      environment: {
        'FERRET_MIXED_CONTROL': '${server.port}',
        'FERRET_MIXED_ROLE': role,
        'FERRET_MIXED_HOME': home,
        'FERRET_MIXED_NAME': '${role[0].toUpperCase()}${role.substring(1)}',
      },
    );
    processes.add(process);
    final log = File('$work/$role.log').openWrite();
    process.stdout.listen(log.add);
    process.stderr.listen(log.add);
    return waiting.timeout(const Duration(minutes: 5));
  }

  final checks = _Checks();
  try {
    final old = await start('old', oldRepo);
    final fresh = await start('new', newRepo);
    // Discovery runs through here: what one announces, the other hears.
    old.announces.listen((data) => fresh.send({'cmd': 'heard', 'data': data}));
    fresh.announces.listen((data) => old.send({'cmd': 'heard', 'data': data}));

    final codecOld = await old.call({'cmd': 'codec'});
    final codecNew = await fresh.call({
      'cmd': 'codec',
      'multicast': codecOld['multicast'],
      'txt': codecOld['txt'],
    });
    final readByOld = await old.call({
      'cmd': 'codec',
      'multicast': codecNew['multicast'],
      'question': base64Encode([0x46, 0x52, 0x54, 0x02]),
      'txt': codecNew['txt'],
    });
    checks
      ..expect(
        'new reads an old multicast announce',
        (codecNew['read'] as Map)['multicast'],
        old.id,
      )
      ..expect(
        'new reads an old DNS-SD TXT record',
        (codecNew['read'] as Map)['txt'],
        'Café ☕ laptop',
      )
      ..expect(
        'old reads a new multicast announce',
        (readByOld['read'] as Map)['multicast'],
        fresh.id,
      )
      ..expect(
        'old reads the TXT record new and Bonjour offer',
        (readByOld['read'] as Map)['txt'],
        'Café ☕ laptop',
      )
      ..expect(
        'old ignores the question a quiet new device sends',
        (readByOld['read'] as Map)['question'],
        null,
      );

    for (final (scanner, shower, label) in [
      (fresh, old, 'new scans the code old shows'),
    ]) {
      final offer = await shower.call({'cmd': 'offer'});
      final paired = await scanner.call({'cmd': 'pair', 'qr': offer['qr']});
      checks.expect('pairing: $label', paired['outcome'], 'Paired');
    }

    Future<bool> connected() async {
      final a = await old.call({'cmd': 'status'});
      final b = await fresh.call({'cmd': 'status'});
      return (a['sessions'] as List).contains(fresh.id) &&
          (b['sessions'] as List).contains(old.id);
    }

    checks.expect('a session opens', await _until(connected), true);
    final status = await fresh.call({'cmd': 'status'});
    checks.expect(
      'new sees old offer clipboard and drop',
      ((status['features'] as Map)[old.id] as List).toSet().containsAll([
        'clipboard',
        'drop',
      ]),
      true,
    );

    for (final (from, to, label) in [
      (old, fresh, 'old → new'),
      (fresh, old, 'new → old'),
    ]) {
      final text = 'copied on ${from.role} ${Random().nextInt(1 << 30)}';
      final landed = to.clips.firstWhere((clip) => clip == text);
      await from.call({'cmd': 'copy', 'text': text});
      checks.expect(
        'clipboard $label',
        await landed
            .then((_) => true)
            .timeout(const Duration(seconds: 10), onTimeout: () => false),
        true,
      );
    }

    for (final (from, to, label) in [
      (old, fresh, 'old → new'),
      (fresh, old, 'new → old'),
    ]) {
      final name = 'from_${from.role}.bin';
      final source = File('$work/$name');
      final random = Random(7);
      await source.writeAsBytes([
        for (var i = 0; i < 1300 * 1024; i++) random.nextInt(256),
      ]);
      final sent = await from.call({
        'cmd': 'send',
        'to': to.id,
        'path': source.path,
      });
      final received = File('$work/${to.role}/inbox/$name');
      final same =
          sent['status'] == 'done' &&
          await received.exists() &&
          _same(await received.readAsBytes(), await source.readAsBytes());
      checks.expect('a 1.3 MB file $label (${sent['status']})', same, true);
    }

    if (Platform.environment['MIXED_QUICK'] == null) {
      // Longer than the 65 s a silent link is dropped after: new skips its
      // own ping while old's keep arriving, and old still hears new.
      stdout.writeln('… waiting 80 s with nothing to send');
      await Future<void>.delayed(const Duration(seconds: 80));
      checks.expect(
        'keepalives hold the link for 80 s',
        await connected(),
        true,
      );
    }

    for (final (peer, label) in [
      (old, 'old restarts'),
      (fresh, 'new restarts'),
    ]) {
      await peer.call({'cmd': 'restart'});
      checks.expect('reconnects after $label', await _until(connected), true);
    }
  } on Object catch (error, stack) {
    checks.fail('run stopped: $error\n$stack');
  } finally {
    for (final peer in peers.values) {
      await peer
          .call({'cmd': 'quit'})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => {},
          );
    }

    for (final process in processes) {
      await process.exitCode.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
    }

    await server.close();
  }

  stdout.writeln(checks.summary);
  exit(checks.failed ? 1 : 0);
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}

Future<bool> _until(Future<bool> Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) {
      return true;
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  return false;
}

class _Peer {
  _Peer(this._socket) {
    _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine);
  }

  final Socket _socket;
  final _ready = Completer<void>();
  final _replies = <int, Completer<Map<String, dynamic>>>{};
  final _announces = StreamController<String>.broadcast();
  final _clips = StreamController<String>.broadcast();
  late String role;
  late String id;
  var _next = 0;

  Future<void> get ready => _ready.future;
  Stream<String> get announces => _announces.stream;
  Stream<String> get clips => _clips.stream;

  void _onLine(String line) {
    final event = jsonDecode(line) as Map<String, dynamic>;
    switch (event['event']) {
      case 'ready':
        role = event['role'] as String;
        id = event['id'] as String;
        _ready.complete();
      case 'announce':
        _announces.add(event['data'] as String);
      case 'clip':
        _clips.add(event['text'] as String);
      case 'reply':
        _replies.remove(event['id'])?.complete(event);
    }
  }

  void send(Map<String, Object?> command) =>
      _socket.writeln(jsonEncode({...command, 'id': -1}));

  Future<Map<String, dynamic>> call(Map<String, Object?> command) async {
    final id = _next++;
    final reply = Completer<Map<String, dynamic>>();
    _replies[id] = reply;
    _socket.writeln(jsonEncode({...command, 'id': id}));
    final answer = await reply.future.timeout(const Duration(seconds: 90));
    if (answer['error'] case final error?) {
      throw StateError('$role: ${command['cmd']} failed: $error');
    }

    return answer;
  }
}

class _Checks {
  final _lines = <String>[];
  var failed = false;

  void expect(String what, Object? actual, Object? wanted) {
    final ok = actual == wanted;
    failed |= !ok;
    final line = '${ok ? 'ok  ' : 'FAIL'} $what${ok ? '' : ' (got $actual)'}';
    _lines.add(line);
    stdout.writeln(line);
  }

  void fail(String why) {
    failed = true;
    _lines.add('FAIL $why');
    stdout.writeln('FAIL $why');
  }

  String get summary =>
      '${failed ? 'Some checks failed' : 'All checks passed'} '
      '(${_lines.where((line) => line.startsWith('ok')).length}/${_lines.length})';
}
