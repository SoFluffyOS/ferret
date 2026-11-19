import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/app_answer.dart';

/// `ferret-cli camera <phone>`: asks a phone for a photo, through the Ferret
/// app running here. The phone shows the request and its owner takes the
/// picture; it lands in the receive folder and on the clipboard, and the
/// command prints where it was saved.
class CameraCommand extends Command<int> {
  CameraCommand(this._environment) {
    argParser
      ..addFlag(
        'document',
        negatable: false,
        help: 'Scan a document instead (iPhone), as a PDF.',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Print the answer as JSON, for scripts.',
      );
  }

  final CliEnvironment _environment;

  /// The phone shows the request for five minutes, then the picture still
  /// has to travel.
  static const _wait = Duration(minutes: 6);

  @override
  String get name => 'camera';

  @override
  String get description =>
      'Ask a phone for a photo. Its owner takes it there, and it lands on '
      'this computer’s clipboard.';

  @override
  String get invocation => 'ferret-cli camera <phone> [--document]';

  @override
  Future<int> run() async {
    final words = argResults?.rest ?? const [];
    if (words.isEmpty) {
      usageException('Name the phone to ask for a photo.');
    }

    final answer = await AppControl(_environment.appRoot, patience: _wait).ask(
      'camera',
      {
        'device': words.join(' '),
        'kind': switch (argResults?['document'] == true) {
          true => 'document',
          false => 'photo',
        },
      },
    );

    return AppAnswer.report(
      _environment,
      answer,
      asJson: argResults?['json'] == true,
      describe: (answer) => switch (answer['path']) {
        final String path => path,
        _ => 'On your clipboard.',
      },
    );
  }
}
