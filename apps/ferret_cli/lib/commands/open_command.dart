import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/app_answer.dart';

/// `ferret-cli open <device> <link>`: opens a web page or a place on one of
/// your devices, like Continue does, through the Ferret app running here.
class OpenCommand extends Command<int> {
  OpenCommand(this._environment) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Print the answer as JSON, for scripts.',
    );
  }

  final CliEnvironment _environment;

  @override
  String get name => 'open';

  @override
  String get description =>
      'Open a web page or a map link on one of your devices.';

  @override
  String get invocation => 'ferret-cli open <device> <link>';

  @override
  Future<int> run() async {
    final words = argResults?.rest ?? const [];
    if (words.length < 2) {
      usageException('Name the device, then the link to open.');
    }

    final device = words.sublist(0, words.length - 1).join(' ');
    final answer = await AppControl(
      _environment.appRoot,
    ).ask('open', {'device': device, 'link': words.last});

    return AppAnswer.report(
      _environment,
      answer,
      asJson: argResults?['json'] == true,
      describe: (answer) => switch (answer['result']) {
        'suggested' => '${answer['device']} shows it, ready to open.',
        _ => 'Opened on ${answer['device']}.',
      },
    );
  }
}
