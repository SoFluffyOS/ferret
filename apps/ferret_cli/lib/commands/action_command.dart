import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/app_answer.dart';

/// `ferret-cli action <computer> [action]`: runs one of another computer's
/// actions (sleep, restart, shut down, sound, or one of its owner's own),
/// through the Ferret app running here. Without an action, lists what that
/// computer offers.
class ActionCommand extends Command<int> {
  ActionCommand(this._environment) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Print the answer as JSON, for scripts.',
    );
  }

  final CliEnvironment _environment;

  /// How long the app may take to answer: the other computer may ask its
  /// owner, count down, and run a command first.
  static const _wait = Duration(minutes: 2);

  @override
  String get name => 'action';

  @override
  String get description =>
      "Run one of another computer's actions, such as sleep or restart, or "
      'list them. That computer asks its owner the first time.';

  @override
  String get invocation => 'ferret-cli action <computer> [action]';

  @override
  Future<int> run() async {
    final words = argResults?.rest ?? const [];
    if (words.isEmpty) {
      usageException('Name the computer, then the action to run there.');
    }

    final asJson = argResults?['json'] == true;
    final control = AppControl(_environment.appRoot, patience: _wait);
    if (words.length == 1) {
      return AppAnswer.report(
        _environment,
        await control.ask('action_list', {'device': words.single}),
        asJson: asJson,
        describe: _describeList,
      );
    }

    final answer = await control.ask('action_run', {
      'device': words.sublist(0, words.length - 1).join(' '),
      'action': words.last,
    });

    return AppAnswer.report(
      _environment,
      answer,
      asJson: asJson,
      describe: (answer) => 'Done on ${answer['device']}.',
    );
  }

  String _describeList(Map<String, Object?> answer) {
    final actions = switch (answer['actions']) {
      final List<Object?> actions => actions,
      _ => const <Object?>[],
    };
    if (actions.isEmpty) {
      return '${answer['device']} offers no actions.';
    }

    return [
      for (final action in actions)
        if (action case {'id': final String id})
          switch (action['title']) {
            final String title => '$id  $title',
            _ => id,
          },
    ].join('\n');
  }
}
