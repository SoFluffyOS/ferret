import 'package:ferret_cli/completion/completion_entry.dart';
import 'package:ferret_cli/completion/completion_spec.dart';
import 'package:ferret_cli/completion/completion_value.dart';

/// Writes the zsh completion script for [CompletionSpec]. It works both
/// from a file named `_ferret-cli` in `$fpath` and with `source`.
abstract final class ZshCompletion {
  static String of(CompletionSpec spec) {
    final buffer = StringBuffer()
      ..writeln('#compdef ferret-cli')
      ..writeln('# ferret-cli completion for zsh. Load it in ~/.zshrc, after')
      ..writeln('# compinit:')
      ..writeln('#   source <(ferret-cli completion zsh)')
      ..writeln()
      ..writeln('_ferret_cli_devices() {')
      ..writeln('  local -a names')
      ..writeln(
        r'  names=(${(f)"$(ferret-cli devices --names 2>/dev/null)"})',
      )
      ..writeln(r"  compadd -X 'device' -- $names")
      ..writeln('}')
      ..writeln()
      ..writeln('_ferret_cli() {')
      ..writeln('  local -a commands')
      ..writeln('  commands=(');
    for (final command in spec.commands) {
      buffer.writeln("    ${_quoted('${command.name}:${command.summary}')}");
    }

    buffer
      ..writeln('  )')
      ..writeln('  if (( CURRENT == 2 )); then')
      ..writeln(r'    if [[ $PREFIX == -* ]]; then')
      ..writeln('      compadd -- --help --version')
      ..writeln('    else')
      ..writeln("      _describe -t commands 'ferret-cli command' commands")
      ..writeln('    fi')
      ..writeln('    return')
      ..writeln('  fi')
      ..writeln()
      ..writeln(r'  case $words[CURRENT-1] in')
      ..writeln('    --to) _ferret_cli_devices; return ;;')
      ..writeln(
        "    --type) _values -s , 'event type' "
        "${CompletionSpec.eventTypes.join(' ')}; return ;;",
      )
      ..writeln('  esac')
      ..writeln()
      ..writeln(r'  case $words[2] in');

    for (final command in spec.commands) {
      buffer.writeln('    ${command.name})');
      _writeCommand(buffer, command, position: 3);
      buffer.writeln('      ;;');
    }

    buffer
      ..writeln('  esac')
      ..writeln('}')
      ..writeln()
      ..writeln(r'if [[ $funcstack[1] == _ferret_cli ]]; then')
      ..writeln(r'  _ferret_cli "$@"')
      ..writeln('else')
      ..writeln('  compdef _ferret_cli ferret-cli')
      ..writeln('fi');
    return '$buffer';
  }

  static void _writeCommand(
    StringBuffer buffer,
    CompletionEntry command, {
    required int position,
  }) {
    buffer
      ..writeln(r'      if [[ $PREFIX == -* ]]; then')
      ..writeln('        compadd -- ${_options(command)}')
      ..writeln('        return')
      ..writeln('      fi');

    if (command.subcommands.isNotEmpty) {
      final subcommands = [
        for (final subcommand in command.subcommands) subcommand.name,
      ];
      buffer
        ..writeln('      if (( CURRENT == $position )); then')
        ..writeln('        compadd -- ${subcommands.join(' ')}')
        ..writeln('        return')
        ..writeln('      fi');
      return;
    }

    switch (command.argument) {
      case CompletionValue.device:
        buffer.writeln(
          '      (( CURRENT == $position )) && _ferret_cli_devices',
        );
      case CompletionValue.file:
        buffer.writeln('      _files');
      case CompletionValue.command:
        buffer.writeln(
          '      (( CURRENT == $position )) && _describe -t commands '
          "'ferret-cli command' commands",
        );
      case CompletionValue.shell:
        buffer.writeln(
          '      (( CURRENT == $position )) && compadd -- '
          '${CompletionSpec.shells.join(' ')}',
        );
      case CompletionValue.none || CompletionValue.eventType:
        return;
    }
  }

  static String _options(CompletionEntry command) => {
    for (final option in command.options) '--${option.name}',
    for (final subcommand in command.subcommands)
      for (final option in subcommand.options) '--${option.name}',
  }.join(' ');

  static String _quoted(String text) => "'${text.replaceAll("'", r"'\''")}'";
}
