import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:ferret_cli/completion/completion_entry.dart';
import 'package:ferret_cli/completion/completion_value.dart';

/// Everything a shell needs to complete `ferret-cli`, read from the
/// commands themselves so it never falls behind them.
class CompletionSpec {
  CompletionSpec._(this.commands);

  /// Reads [runner]'s commands and options.
  factory CompletionSpec.of(CommandRunner<Object?> runner) => CompletionSpec._(
    [
      for (final command in runner.commands.values.toSet())
        if (!command.hidden) _commandOf(command, nested: false),
    ]..sort((first, second) => first.name.compareTo(second.name)),
  );

  final List<CompletionEntry> commands;

  static const String program = 'ferret-cli';

  /// `watch --type` takes these, and the group names before the dot.
  static const List<String> eventTypes = [
    'action.run',
    'battery',
    'call',
    'call.ended',
    'call.ringing',
    'clipboard.received',
    'device',
    'device.connected',
    'device.disconnected',
    'device.reconnecting',
    'file.received',
    'notification.received',
    'transfer',
    'transfer.done',
    'transfer.progress',
  ];

  static const List<String> shells = ['bash', 'fish', 'zsh'];

  /// Commands whose first word is a device name.
  static const Set<String> _deviceFirst = {
    'action',
    'camera',
    'notify',
    'open',
    'ring',
    'unpair',
    'wake',
  };

  static CompletionEntry _commandOf(
    Command<Object?> command, {
    required bool nested,
  }) => CompletionEntry(
    name: command.name,
    summary: summaryOf(command.description),
    options: _optionsOf(command.argParser),
    argument: switch (command.name) {
      _ when nested => CompletionValue.none,
      'send' => CompletionValue.file,
      'help' => CompletionValue.command,
      'completion' => CompletionValue.shell,
      final name when _deviceFirst.contains(name) => CompletionValue.device,
      _ => CompletionValue.none,
    },
    subcommands: [
      for (final subcommand in command.subcommands.values.toSet())
        if (!subcommand.hidden) _commandOf(subcommand, nested: true),
    ]..sort((first, second) => first.name.compareTo(second.name)),
  );

  static List<CompletionOption> _optionsOf(ArgParser parser) => [
    for (final option in parser.options.values)
      if (!option.hide)
        (
          name: option.name,
          help: summaryOf(option.help ?? ''),
          value: switch (option.name) {
            _ when option.isFlag => CompletionValue.none,
            'to' => CompletionValue.device,
            'type' => CompletionValue.eventType,
            _ => CompletionValue.file,
          },
        ),
  ];

  /// The first sentence of [text], without its full stop, on one line.
  static String summaryOf(String text) {
    final line = text.split('\n').first.trim();
    final end = line.indexOf('. ');
    final sentence = switch (end) {
      -1 => line,
      _ => line.substring(0, end),
    };

    return switch (sentence.endsWith('.')) {
      true => sentence.substring(0, sentence.length - 1),
      false => sentence,
    };
  }
}
