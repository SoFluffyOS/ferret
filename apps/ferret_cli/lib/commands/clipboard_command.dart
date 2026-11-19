import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:core/core.dart';
import 'package:ferret_cli/cli_environment.dart';
import 'package:ferret_cli/commands/app_answer.dart';

/// `ferret-cli clipboard get|send`: reads the last clip that arrived from
/// your devices, or sends text to them, through the Ferret app running on
/// this computer.
class ClipboardCommand extends Command<int> {
  ClipboardCommand(CliEnvironment environment) {
    addSubcommand(_GetCommand(environment));
    addSubcommand(_SendCommand(environment));
  }

  @override
  String get name => 'clipboard';

  @override
  String get description =>
      'Print the last clip from your devices, or send text to them.';
}

class _GetCommand extends Command<int> {
  _GetCommand(this._environment) {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Print the clip with where and when it came from, as JSON.',
    );
  }

  final CliEnvironment _environment;

  @override
  String get name => 'get';

  @override
  String get description =>
      'Print the last text that arrived from another device. Private clips '
      'and images are never printed.';

  @override
  Future<int> run() async {
    final answer = await AppControl(
      _environment.appRoot,
    ).ask('clipboard_get');

    return AppAnswer.report(
      _environment,
      answer,
      asJson: argResults?['json'] == true,
      describe: (answer) => '${answer['text']}',
    );
  }
}

class _SendCommand extends Command<int> {
  _SendCommand(this._environment) {
    argParser
      ..addOption('to', help: 'Send to this device only.', valueHelp: 'device')
      ..addFlag(
        'json',
        negatable: false,
        help: 'Print the answer as JSON, for scripts.',
      );
  }

  final CliEnvironment _environment;

  @override
  String get name => 'send';

  @override
  String get description =>
      'Send text to the clipboard of your devices. Without text, reads it '
      'from standard input.';

  @override
  String get invocation => 'ferret-cli clipboard send [text] [--to <device>]';

  @override
  Future<int> run() async {
    final words = argResults?.rest ?? const [];
    final text = switch (words) {
      [] => await _readInput(),
      _ => words.join(' '),
    };
    final device = argResults?['to'] as String?;

    final answer = await AppControl(_environment.appRoot).ask(
      'clipboard_send',
      {'text': text, 'device': ?device},
    );

    return AppAnswer.report(
      _environment,
      answer,
      asJson: argResults?['json'] == true,
      describe: (answer) => switch (answer['device']) {
        final String name => 'Sent to $name.',
        _ => 'Sent to your devices.',
      },
    );
  }

  static Future<String> _readInput() async {
    if (stdin.hasTerminal) {
      return '';
    }

    final text = await stdin.transform(utf8.decoder).join();
    return text.trimRight();
  }
}
