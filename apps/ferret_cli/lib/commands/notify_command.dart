import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/app_answer.dart';

/// `ferret-cli notify <device> <title> [body]`: shows a notice on one of
/// your devices, once its owner allowed scripts from this computer there.
class NotifyCommand extends Command<int> {
  NotifyCommand(this._environment) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Print the answer as JSON, for scripts.',
    );
  }

  final CliEnvironment _environment;

  @override
  String get name => 'notify';

  @override
  String get description =>
      'Show a notice on one of your devices. Turn on "Let scripts on this '
      'computer show notices here" on that device first.';

  @override
  String get invocation => 'ferret-cli notify <device> <title> [body]';

  @override
  Future<int> run() async {
    final words = argResults?.rest ?? const [];
    if (words.length < 2) {
      usageException(
        'Name the device, then the title (and a body if you like).',
      );
    }

    final answer = await AppControl(_environment.appRoot).ask('notify', {
      'device': words.first,
      'title': words[1],
      'body': words.skip(2).join(' '),
    });

    return AppAnswer.report(
      _environment,
      answer,
      asJson: argResults?['json'] == true,
      describe: (answer) => 'Shown on ${answer['device']}.',
    );
  }
}
