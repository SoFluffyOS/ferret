/// The `ferret` command line.
library;

import 'package:args/command_runner.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/commands.dart';

export 'package:ferret_cli/cli_environment.dart';

CommandRunner<int> buildRunner(CliEnvironment environment) =>
    CommandRunner<int>(
        'ferret',
        'Continue what you were doing on any of your devices.\n\n'
            'Keeps its identity, pairings and settings in '
            '~/.sofluffy/ferret/cli (%USERPROFILE%\\.sofluffy\\ferret\\cli on '
            'Windows). Set FERRET_HOME to use another folder instead of '
            '~/.sofluffy/ferret.',
      )
      ..addCommand(DaemonCommand(environment))
      ..addCommand(DevicesCommand(environment))
      ..addCommand(OfferCommand(environment))
      ..addCommand(PairCommand(environment))
      ..addCommand(UnpairCommand(environment));
