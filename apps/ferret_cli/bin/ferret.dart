import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/ferret_cli.dart';

Future<void> main(List<String> arguments) async {
  Log.minimum = .warning;

  try {
    final environment = await CliEnvironment.forThisUser();
    exitCode = await buildRunner(environment).run(arguments) ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    exitCode = ExitCodes.usage;
  }
}
