import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/app_answer.dart';

/// `ferret-cli ring <device>`: asks the Ferret app running on this computer
/// to ring one of your devices, even when it's on silent.
class RingCommand extends Command<int> {
  RingCommand(this._environment) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Print the answer as JSON, for scripts.',
    );
  }

  final CliEnvironment _environment;

  @override
  String get name => 'ring';

  @override
  String get description =>
      'Ring one of your devices, through the Ferret app running here.';

  @override
  String get invocation => 'ferret-cli ring <device>';

  @override
  Future<int> run() async {
    final words = argResults?.rest ?? const [];
    if (words.isEmpty) {
      usageException('Name the device to ring.');
    }

    final answer = await AppControl(
      _environment.appRoot,
    ).ask('ring', {'device': words.join(' ')});

    return AppAnswer.report(
      _environment,
      answer,
      asJson: argResults?['json'] == true,
      describe: (answer) => '${answer['device']} is ringing.',
    );
  }
}
