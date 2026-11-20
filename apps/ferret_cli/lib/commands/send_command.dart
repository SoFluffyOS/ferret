import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/app_answer.dart';
import 'package:ferret_cli/exit_codes.dart';

/// `ferret-cli send <file or folder>…`: hands the files to the Ferret app
/// running on this computer, which sends them to your device (or asks which
/// one). With `--to`, they go straight to that device. A folder goes with
/// everything inside it, and `-` reads more paths from standard input.
class SendCommand extends Command<int> {
  SendCommand(this._environment) {
    argParser
      ..addOption(
        'to',
        help: 'Send to this device, without asking which one.',
        valueHelp: 'device',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Print the answer as JSON, for scripts.',
      );
  }

  final CliEnvironment _environment;

  /// Stands for "read the paths from standard input, one per line".
  static const String _fromInput = '-';

  @override
  String get name => 'send';

  @override
  String get description =>
      'Send files or folders with the Ferret app running on this computer. '
      'Give - to read paths from standard input, one per line.';

  @override
  String get invocation => 'ferret-cli send <file or folder>… [--to <device>]';

  bool get _asJson => argResults?['json'] == true;

  @override
  Future<int> run() async {
    final named = argResults?.rest ?? const [];
    final files = [
      for (final file in named)
        if (file != _fromInput) file,
      if (named.contains(_fromInput)) ...await _readPaths(),
    ];
    if (files.isEmpty) {
      usageException('Name at least one file or folder to send.');
    }

    final paths = <String>[];
    var folders = 0;
    for (final file in files) {
      final entity = File(file).absolute;
      final isFolder = Directory(entity.path).existsSync();
      if (!entity.existsSync() && !isFolder) {
        return _missing(file);
      }

      if (isFolder) {
        folders++;
      }
      paths.add(entity.path);
    }

    if (argResults?['to'] case final String device) {
      return _sendTo(device, paths);
    }

    return _handOver(paths, folders: folders);
  }

  Future<int> _sendTo(String device, List<String> paths) async {
    final answer = await AppControl(
      _environment.appRoot,
    ).ask('send_files', {'device': device, 'paths': paths});

    return AppAnswer.report(
      _environment,
      answer,
      asJson: _asJson,
      describe: (answer) => switch (paths.length) {
        1 => 'Sending it to ${answer['device']}.',
        final count => 'Sending $count to ${answer['device']}.',
      },
    );
  }

  Future<int> _handOver(List<String> paths, {required int folders}) async {
    final handoff = SendHandoff(_environment.appRoot);
    final taken = await handoff.handOver(paths);
    await handoff.dispose();
    if (!taken) {
      return AppAnswer.report(
        _environment,
        null,
        asJson: _asJson,
        describe: (_) => '',
      );
    }

    if (_asJson) {
      _environment.out.writeln(
        jsonEncode({'ok': true, 'result': 'handed_over', 'paths': paths}),
      );
      return ExitCodes.ok;
    }

    _environment.out.writeln(switch ((paths.length, folders)) {
      (1, 1) => 'Handed 1 folder to Ferret.',
      (1, _) => 'Handed 1 file to Ferret.',
      (final count, 0) => 'Handed $count files to Ferret.',
      (final count, _) => 'Handed $count files and folders to Ferret.',
    });
    return ExitCodes.ok;
  }

  int _missing(String file) {
    if (_asJson) {
      _environment.out.writeln(
        jsonEncode({'ok': false, 'error': 'no_such_file', 'path': file}),
      );
    }

    _environment.err.writeln('No such file or folder: $file');
    return ExitCodes.noInput;
  }

  Future<List<String>> _readPaths() async {
    final input = await _environment.readInput() ?? '';
    return [
      for (final line in const LineSplitter().convert(input))
        if (line.trim().isNotEmpty) line,
    ];
  }
}
