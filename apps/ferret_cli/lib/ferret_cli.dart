/// The `ferret` command line.
library;

import 'package:args/command_runner.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/commands.dart';

export 'package:ferret_cli/cli_environment.dart';

CommandRunner<int> buildRunner(CliEnvironment environment) =>
    CommandRunner<int>(
        'ferret',
        'Continue what you were doing on any of your devices.',
      )
      ..addCommand(DaemonCommand(environment))
      ..addCommand(DevicesCommand(environment))
      ..addCommand(OfferCommand(environment))
      ..addCommand(PairCommand(environment))
      ..addCommand(UnpairCommand(environment));
