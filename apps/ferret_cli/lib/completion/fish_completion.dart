import 'package:ferret_cli/completion/completion_entry.dart';
import 'package:ferret_cli/completion/completion_spec.dart';
import 'package:ferret_cli/completion/completion_value.dart';

/// Writes the fish completion script for [CompletionSpec].
abstract final class FishCompletion {
  static const String _devices = "'(ferret-cli devices --names 2>/dev/null)'";

  static String of(CompletionSpec spec) {
    final buffer = StringBuffer()
      ..writeln('# ferret-cli completion for fish. Save it once:')
      ..writeln(
        '#   ferret-cli completion fish > '
        '~/.config/fish/completions/ferret-cli.fish',
      )
      ..writeln()
      ..writeln('function __ferret_cli_needs_command')
      ..writeln('    test (count (commandline -opc)) -eq 1')
      ..writeln('end')
      ..writeln()
      ..writeln('function __ferret_cli_using')
      ..writeln('    set -l tokens (commandline -opc)')
      ..writeln(r'    set -l wanted (count $argv)')
      ..writeln(r'    test (count $tokens) -gt $wanted; or return 1')
      ..writeln(r'    for index in (seq $wanted)')
      ..writeln(
        r'        test "$tokens[(math $index + 1)]" = "$argv[$index]"; '
        'or return 1',
      )
      ..writeln('    end')
      ..writeln('end')
      ..writeln()
      ..writeln('function __ferret_cli_first_word')
      ..writeln('    set -l tokens (commandline -opc)')
      ..writeln(
        r'    test (count $tokens) -eq (math (count $argv) + 1); '
        'or return 1',
      )
      ..writeln(r'    __ferret_cli_using $argv')
      ..writeln('end')
      ..writeln()
      ..writeln('complete -c ferret-cli -f')
      ..writeln(
        'complete -c ferret-cli -n __ferret_cli_needs_command -l help '
        "-d 'Print this usage information'",
      )
      ..writeln(
        'complete -c ferret-cli -n __ferret_cli_needs_command -l version '
        "-d 'Print the version'",
      );

    for (final command in spec.commands) {
      buffer.writeln(
        'complete -c ferret-cli -n __ferret_cli_needs_command '
        '-a ${command.name} -d ${_quoted(command.summary)}',
      );
    }

    for (final command in spec.commands) {
      _writeCommand(buffer, command, path: [command.name], spec: spec);
    }

    return '$buffer';
  }

  static void _writeCommand(
    StringBuffer buffer,
    CompletionEntry command, {
    required List<String> path,
    required CompletionSpec spec,
  }) {
    final using = _quoted('__ferret_cli_using ${path.join(' ')}');
    final first = _quoted('__ferret_cli_first_word ${path.join(' ')}');

    for (final option in command.options) {
      final value = switch (option.value) {
        CompletionValue.device => ' -x -a $_devices',
        CompletionValue.eventType =>
          " -x -a '${CompletionSpec.eventTypes.join(' ')}'",
        CompletionValue.file => ' -r',
        _ => '',
      };
      buffer.writeln(
        'complete -c ferret-cli -n $using -l ${option.name}$value '
        '-d ${_quoted(option.help)}',
      );
    }

    for (final subcommand in command.subcommands) {
      buffer.writeln(
        'complete -c ferret-cli -n $first -a ${subcommand.name} '
        '-d ${_quoted(subcommand.summary)}',
      );
      _writeCommand(
        buffer,
        subcommand,
        path: [...path, subcommand.name],
        spec: spec,
      );
    }

    final argument = switch (command.argument) {
      CompletionValue.device => '-n $first -a $_devices',
      CompletionValue.file => '-n $using -F',
      CompletionValue.shell =>
        "-n $first -a '${CompletionSpec.shells.join(' ')}'",
      CompletionValue.command =>
        "-n $first -a '${[for (final command in spec.commands) command.name].join(' ')}'",
      _ => null,
    };
    if (argument != null) {
      buffer.writeln('complete -c ferret-cli $argument');
    }
  }

  static String _quoted(String text) =>
      "'${text.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
}
