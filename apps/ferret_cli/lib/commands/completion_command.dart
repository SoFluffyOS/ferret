import 'package:args/command_runner.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/completion/completion.dart';
import 'package:ferret_cli/exit_codes.dart';

/// `ferret-cli completion <bash|zsh|fish>`: prints the script that teaches
/// that shell the commands, their options and your device names.
class CompletionCommand extends Command<int> {
  CompletionCommand(this._environment);

  final CliEnvironment _environment;

  @override
  String get name => 'completion';

  @override
  String get description =>
      'Print tab completion for your shell: commands, options and device '
      'names.\n\n'
      'bash, in ~/.bashrc:  source <(ferret-cli completion bash)\n'
      'zsh, in ~/.zshrc:    source <(ferret-cli completion zsh)\n'
      'fish, once:          ferret-cli completion fish > '
      '~/.config/fish/completions/ferret-cli.fish';

  @override
  String get invocation => 'ferret-cli completion <bash|zsh|fish>';

  @override
  Future<int> run() async {
    final shell = switch (argResults?.rest) {
      [final shell] => shell,
      _ => usageException('Name the shell: bash, zsh or fish.'),
    };
    final spec = CompletionSpec.of(
      runner ?? CommandRunner<int>(CompletionSpec.program, ''),
    );

    final script = switch (shell) {
      'bash' => BashCompletion.of(spec),
      'zsh' => ZshCompletion.of(spec),
      'fish' => FishCompletion.of(spec),
      _ => usageException(
        "ferret-cli can't complete $shell yet. Pick bash, zsh or fish.",
      ),
    };

    _environment.out.write(script);
    return ExitCodes.ok;
  }
}
