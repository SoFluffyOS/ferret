import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:core/logging/logging.dart';
import 'package:path/path.dart' as p;

/// Answers one `ferret-cli` command, such as `ring` or `clipboard get`,
/// with a JSON object.
typedef AppControlHandler = Future<Map<String, Object?>> Function(
  String command,
  Map<String, Object?> arguments,
);

/// Lets `ferret-cli` ask the running app to do something and wait for the
/// answer, such as ringing a device or reading the last clip that arrived.
///
/// Like [SendHandoff], the app listens on loopback only and writes the port
/// and a one-time secret to a file in its own folder, so only the same user
/// can ask.
class AppControl {
  AppControl(String directory, {this.patience = answerPatience})
    : _file = File(p.join(directory, _fileName));

  static const String _fileName = 'app_control.json';
  static const Duration _connectPatience = Duration(seconds: 2);

  /// How long a command may take, such as waiting for a phone to ring.
  static const Duration answerPatience = Duration(seconds: 20);

  /// How long [ask] waits for the app's answer. Longer for a command that
  /// waits on a person, such as an action another computer asks about.
  final Duration patience;

  final File _file;
  ServerSocket? _server;
  String _secret = '';
  AppControlHandler? _handler;

  /// Starts answering commands with [handler]. Quietly does nothing when
  /// this computer won't let it listen.
  Future<void> listen(AppControlHandler handler) async {
    if (_server != null) {
      return;
    }

    try {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      _secret = _newSecret();
      _handler = handler;
      await _file.parent.create(recursive: true);
      await _file.writeAsString('');
      await _keepPrivate(_file);
      await _file.writeAsString(
        jsonEncode({'port': server.port, 'secret': _secret}),
        flush: true,
      );
      _server = server;
      server.listen((socket) => unawaited(_answer(socket)));
    } on IOException catch (error) {
      printWarning('App control is off: ${error.runtimeType}');
    }
  }

  /// Asks the running app to run [command]. Null when no app is running.
  Future<Map<String, Object?>?> ask(
    String command, [
    Map<String, Object?> arguments = const {},
  ]) async {
    try {
      final address = jsonDecode(await _file.readAsString());
      if (address case {
        'port': final int port,
        'secret': final String secret,
      }) {
        final socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          port,
          timeout: _connectPatience,
        );
        socket.writeln(
          jsonEncode({
            'secret': secret,
            'command': command,
            'arguments': arguments,
          }),
        );
        await socket.flush();
        final line = await _firstLine(socket).timeout(patience);
        socket.destroy();

        return switch (jsonDecode(line)) {
          final Map<String, Object?> answer => answer,
          _ => null,
        };
      }

      return null;
    } on Object {
      return null;
    }
  }

  Future<void> dispose() async {
    final server = _server;
    _server = null;
    _handler = null;
    await server?.close();
    if (server == null) {
      return;
    }

    try {
      await _file.delete();
    } on FileSystemException {
      return;
    }
  }

  Future<void> _answer(Socket socket) async {
    try {
      final line = await _firstLine(socket).timeout(_connectPatience);
      final request = jsonDecode(line);
      if (request
          case {
            'secret': final String secret,
            'command': final String command,
            'arguments': final Map<String, Object?> arguments,
          }
          when secret == _secret) {
        final handler = _handler;
        if (handler == null) {
          return;
        }

        final answer = await handler(command, arguments);
        socket.writeln(jsonEncode(answer));
        await socket.flush();
      }
    } on Object catch (error) {
      printWarning('App control request failed: ${error.runtimeType}');
    } finally {
      socket.destroy();
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

  static Future<void> _keepPrivate(File file) async {
    if (Platform.isWindows) {
      return;
    }

    await Process.run('chmod', ['600', file.path]);
  }
}
