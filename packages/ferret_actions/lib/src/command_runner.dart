import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ferret_actions/src/command_outcome.dart';

/// Starts a program, as `Process.start` does.
typedef StartProcess = Future<Process> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
});

/// Runs one program with its arguments, never through a shell, and stops
/// it when it runs too long.
class CommandRunner {
  CommandRunner({
    StartProcess? start,
    this.outputLimit = 4096,
    this.killGrace = const Duration(seconds: 2),
  }) : _start = start ?? Process.start;

  final StartProcess _start;

  /// How many characters of output to keep. The rest is read and dropped,
  /// so a chatty program never blocks on a full pipe.
  final int outputLimit;

  /// How long a program gets to end by itself after being asked to, before
  /// it is killed.
  final Duration killGrace;

  /// Apps started from Finder get a bare `PATH`. These are where a Mac's
  /// own tools usually live.
  static const _macPaths = ['/opt/homebrew/bin', '/usr/local/bin'];

  /// Runs [command] (program first) from the home folder and waits for it
  /// to end, at most [timeout].
  Future<CommandOutcome> run(
    List<String> command, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (command.isEmpty) {
      return const CommandOutcome.notStarted('');
    }

    final Process process;
    try {
      process = await _start(
        command.first,
        command.sublist(1),
        workingDirectory: _home(),
        environment: _environment(),
      );
    } on ProcessException catch (error) {
      return CommandOutcome.notStarted(error.message);
    }

    final output = StringBuffer();
    final streams = [
      _collect(process.stdout, output),
      _collect(process.stderr, output),
    ];
    unawaited(process.stdin.close().catchError((Object _) {}));

    final exitCode = await process.exitCode
        .then<int?>((code) => code)
        .timeout(timeout, onTimeout: () => null);
    if (exitCode != null) {
      await Future.wait(streams).timeout(killGrace, onTimeout: () => const []);
      return CommandOutcome(exitCode: exitCode, output: output.toString());
    }

    process.kill();
    await process.exitCode.timeout(
      killGrace,
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );

    return CommandOutcome(output: output.toString(), timedOut: true);
  }

  Future<void> _collect(Stream<List<int>> stream, StringBuffer output) async {
    final text = stream.transform(const Utf8Decoder(allowMalformed: true));
    try {
      await for (final chunk in text) {
        final room = outputLimit - output.length;
        if (room <= 0) {
          continue;
        }

        output.write(chunk.substring(0, room.clamp(0, chunk.length)));
      }
    } on Object {
      return;
    }
  }

  String? _home() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null || !Directory(home).existsSync()) {
      return null;
    }

    return home;
  }

  Map<String, String>? _environment() {
    if (!Platform.isMacOS) {
      return null;
    }

    final path = Platform.environment['PATH'] ?? '/usr/bin:/bin';
    final known = path.split(':');
    final extra = _macPaths.where((folder) => !known.contains(folder));

    return {
      'PATH': [...known, ...extra].join(':'),
    };
  }
}
