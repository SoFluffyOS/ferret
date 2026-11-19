/// The `ferret-cli` command line. The app binary is `ferret`.
library;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/commands.dart';
import 'package:ferret_cli/exit_codes.dart';

export 'package:ferret_cli/cli_environment.dart';
export 'package:ferret_cli/exit_codes.dart';

const String cliVersion = '0.1.0';

CommandRunner<int> buildRunner(CliEnvironment environment) =>
    _FerretRunner(environment)
      ..addCommand(ClipboardCommand(environment))
      ..addCommand(DaemonCommand(environment))
      ..addCommand(DevicesCommand(environment))
      ..addCommand(OfferCommand(environment))
      ..addCommand(PairCommand(environment))
      ..addCommand(RingCommand(environment))
      ..addCommand(SendCommand(environment))
      ..addCommand(UnpairCommand(environment));

class _FerretRunner extends CommandRunner<int> {
  _FerretRunner(this._environment)
    : super(
        'ferret-cli',
        'Continue what you were doing on any of your devices.\n\n'
            'Keeps its identity, pairings and settings in '
            '~/.sofluffy/ferret/cli (%USERPROFILE%\\.sofluffy\\ferret\\cli on '
            'Windows). Set FERRET_HOME to use another folder instead of '
            '~/.sofluffy/ferret.',
      ) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the version.',
    );
  }

  final CliEnvironment _environment;

  @override
  String get usageFooter => '\n${ExitCodes.description}';

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      _environment.out.writeln('ferret-cli $cliVersion');
      return ExitCodes.ok;
    }

    return super.runCommand(topLevelResults);
  }
}
