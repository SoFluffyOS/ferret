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

/// Streams what happens in the running app to `ferret-cli watch`, one JSON
/// object per event, for as long as the command keeps listening.
typedef AppControlWatcher = Stream<Map<String, Object?>> Function(
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

  /// The command that keeps the connection open and streams events.
  static const String watchCommand = 'watch';
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
  AppControlWatcher? _watcher;

  /// Starts answering commands with [handler], and [watchCommand] with
  /// [watch]. Quietly does nothing when this computer won't let it listen.
  Future<void> listen(
    AppControlHandler handler, {
    AppControlWatcher? watch,
  }) async {
    if (_server != null) {
      return;
    }

    try {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      _secret = _newSecret();
      _handler = handler;
      _watcher = watch;
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
      final socket = await _send(command, arguments);
      if (socket == null) {
        return null;
      }

      final line = await _firstLine(socket).timeout(patience);
      socket.destroy();

      return switch (jsonDecode(line)) {
        final Map<String, Object?> answer => answer,
        _ => null,
      };
    } on Object {
      return null;
    }
  }

  /// What happens in the running app from now on, one JSON object per
  /// event, until the returned stream's listener cancels or the app quits.
  /// Null when no app is running.
  Future<Stream<Map<String, Object?>>?> watch([
    Map<String, Object?> arguments = const {},
  ]) async {
    final Socket? socket;
    try {
      socket = await _send(watchCommand, arguments);
    } on Object {
      return null;
    }

    if (socket == null) {
      return null;
    }

    final controller = StreamController<Map<String, Object?>>();
    final lines = utf8.decoder.bind(socket).transform(const LineSplitter());
    StreamSubscription<String>? subscription;
    controller
      ..onListen = () {
        subscription = lines.listen(
          (line) => _addEvent(controller, line),
          onError: (Object _) => unawaited(controller.close()),
          onDone: () => unawaited(controller.close()),
        );
      }
      ..onCancel = () async {
        await subscription?.cancel();
        socket?.destroy();
      };

    return controller.stream;
  }

  static void _addEvent(
    StreamController<Map<String, Object?>> controller,
    String line,
  ) {
    try {
      if (jsonDecode(line) case final Map<String, Object?> event) {
        controller.add(event);
      }
    } on FormatException {
      return;
    }
  }

  Future<Socket?> _send(String command, Map<String, Object?> arguments) async {
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
      return socket;
    }

    return null;
  }

  Future<void> dispose() async {
    final server = _server;
    _server = null;
    _handler = null;
    _watcher = null;
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
    unawaited(socket.done.then<void>((_) {}, onError: (Object _) {}));
    final lines = StreamIterator(
      utf8.decoder.bind(socket).transform(const LineSplitter()),
    );
    try {
      if (!await lines.moveNext().timeout(_connectPatience)) {
        return;
      }

      final request = jsonDecode(lines.current);
      if (request
          case {
            'secret': final String secret,
            'command': final String command,
            'arguments': final Map<String, Object?> arguments,
          }
          when secret == _secret) {
        if (command == watchCommand) {
          await _stream(socket, lines, arguments);
          return;
        }

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
      await lines.cancel();
      socket.destroy();
    }
  }

  /// Writes each event to [socket] until the other end hangs up or the
  /// events end.
  Future<void> _stream(
    Socket socket,
    StreamIterator<String> lines,
    Map<String, Object?> arguments,
  ) async {
    final watcher = _watcher;
    if (watcher == null) {
      socket.writeln(jsonEncode({'ok': false, 'error': 'not_supported'}));
      await socket.flush();
      return;
    }

    final finished = Completer<void>();
    void finish() {
      if (!finished.isCompleted) {
        finished.complete();
      }
    }

    final events = watcher(arguments).listen(
      (event) => socket.writeln(jsonEncode(event)),
      onDone: finish,
    );
    unawaited(_untilHungUp(lines).whenComplete(finish));
    await finished.future;
    await events.cancel();
    await socket.flush();
  }

  static Future<void> _untilHungUp(StreamIterator<String> lines) async {
    try {
      while (await lines.moveNext()) {}
    } on Object {
      return;
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
