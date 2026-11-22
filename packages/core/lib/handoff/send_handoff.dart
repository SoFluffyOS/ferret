import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:core/logging/logging.dart';
import 'package:path/path.dart' as p;

/// Passes `ferret send <file>…` on to the Ferret that is already running,
/// so a file manager's "Send with Ferret" never starts a second one. The
/// app listens; the app's own later runs and the `ferret` command line hand
/// over.
///
/// The running app listens on this computer only (loopback) and writes the
/// port and a one-time secret to a file in its own folder. Only someone who
/// can read that folder, which is the same user, can hand files over.
class SendHandoff {
  SendHandoff(String directory) : _file = File(p.join(directory, _fileName)) {
    _requests = .broadcast(onListen: _deliverWaiting);
  }

  static const String _fileName = 'send_handoff.json';
  static const Duration _patience = Duration(seconds: 2);
  static const String _taken = 'ok';

  final File _file;
  late final StreamController<List<String>> _requests;
  final List<List<String>> _waiting = [];
  ServerSocket? _server;
  Future<void>? _listening;
  String _secret = '';

  /// Files later `ferret send` runs handed over, as absolute paths. An
  /// empty list is a later launch asking to see the window ([wakeUp]).
  /// Requests taken before anyone listens wait for the first listener, so
  /// a launch while this one is still getting ready isn't lost.
  Stream<List<String>> get requests => _requests.stream;

  /// Starts taking files from later runs, as early as it can, so a second
  /// launch never starts a second Ferret. Calling it again does nothing
  /// more. Quietly does nothing when this computer won't let it listen.
  Future<void> listen() => _listening ??= _listen();

  Future<void> _listen() async {
    try {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      _secret = _newSecret();
      await _file.parent.create(recursive: true);
      await _file.writeAsString('');
      await _keepPrivate(_file);
      await _file.writeAsString(
        jsonEncode({'port': server.port, 'secret': _secret}),
        flush: true,
      );
      _server = server;
      server.listen((socket) => unawaited(_take(socket)));
    } on IOException catch (error) {
      printWarning('Send handoff is off: ${error.runtimeType}');
    }
  }

  /// Hands [paths] to the running Ferret. False when there is none, so
  /// this run should start up and send them itself.
  Future<bool> handOver(List<String> paths) async {
    if (paths.isEmpty) {
      return false;
    }

    return _send(paths);
  }

  /// Asks the running Ferret to show its window, as a second launch from
  /// the app menu does while the first one sits in the tray. It arrives on
  /// [requests] with no files. False when no Ferret is running.
  Future<bool> wakeUp() => _send(const []);

  Future<bool> _send(List<String> paths) async {
    try {
      final address = jsonDecode(await _file.readAsString());
      if (address case {
        'port': final int port,
        'secret': final String secret,
      }) {
        final socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          port,
          timeout: _patience,
        );
        socket.writeln(jsonEncode({'secret': secret, 'paths': paths}));
        await socket.flush();
        final answer = await _firstLine(socket).timeout(_patience);
        socket.destroy();

        return answer == _taken;
      }

      return false;
    } on Object {
      return false;
    }
  }

  Future<void> dispose() async {
    final server = _server;
    _server = null;
    await server?.close();
    await _requests.close();
    if (server == null) {
      return;
    }

    try {
      await _file.delete();
    } on FileSystemException {
      return;
    }
  }

  Future<void> _take(Socket socket) async {
    try {
      final line = await _firstLine(socket).timeout(_patience);
      final request = jsonDecode(line);
      if (request
          case {
            'secret': final String secret,
            'paths': final List<Object?> paths,
          }
          when secret == _secret) {
        _request(paths.whereType<String>().toList());
        socket.writeln(_taken);
        await socket.flush();
      }
    } on Object {
      // Anything that isn't a well-formed request from a later run is
      // dropped without an answer.
    } finally {
      socket.destroy();
    }
  }

  void _request(List<String> paths) {
    if (!_requests.hasListener) {
      _waiting.add(paths);
      return;
    }

    _requests.add(paths);
  }

  void _deliverWaiting() {
    final waiting = List.of(_waiting);
    _waiting.clear();
    for (final paths in waiting) {
      _requests.add(paths);
    }
  }

  static Future<String> _firstLine(Socket socket) =>
      utf8.decoder.bind(socket).transform(const LineSplitter()).first;

  static String _newSecret() {
    final random = Random.secure();
    final bytes = [
      for (var index = 0; index < 24; index++) random.nextInt(256),
    ];

    return base64UrlEncode(bytes);
  }

  /// Owner only, where the system has file modes. On Windows the profile
  /// folder is already private to the user.
  static Future<void> _keepPrivate(File file) async {
    if (Platform.isWindows) {
      return;
    }

    await Process.run('chmod', ['600', file.path]);
  }
}
