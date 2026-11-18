import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/exit_codes.dart';

/// `ferret send <file>…`: hands the files to the Ferret app running on this
/// computer, which sends them to your device (or asks which one).
class SendCommand extends Command<int> {
  SendCommand(this._environment);

  final CliEnvironment _environment;

  @override
  String get name => 'send';

  @override
  String get description =>
      'Send files with the Ferret app running on this computer.';

  @override
  String get invocation => 'ferret send <file>…';

  @override
  Future<int> run() async {
    final files = argResults?.rest ?? const [];
    if (files.isEmpty) {
      usageException('Name at least one file to send.');
    }

    final paths = <String>[];
    for (final file in files) {
      final entity = File(file).absolute;
      if (!entity.existsSync() && !Directory(entity.path).existsSync()) {
        _environment.err.writeln('No such file: $file');
        return ExitCodes.noInput;
      }
      paths.add(entity.path);
    }

    final handoff = SendHandoff(_environment.appRoot);
    final taken = await handoff.handOver(paths);
    await handoff.dispose();
    if (!taken) {
      _environment.err.writeln(
        "The Ferret app isn't running on this computer. Open it, then try "
        'again.',
      );
      return ExitCodes.unavailable;
    }

    _environment.out.writeln(switch (paths.length) {
      1 => 'Handed 1 file to Ferret.',
      final count => 'Handed $count files to Ferret.',
    });
    return ExitCodes.ok;
  }
}
