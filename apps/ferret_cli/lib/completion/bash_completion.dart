import 'package:ferret_cli/completion/completion_entry.dart';
import 'package:ferret_cli/completion/completion_spec.dart';
import 'package:ferret_cli/completion/completion_value.dart';

/// Writes the bash completion script for [CompletionSpec].
abstract final class BashCompletion {
  static String of(CompletionSpec spec) {
    final commands = [for (final command in spec.commands) command.name];
    final buffer = StringBuffer()
      ..writeln('# ferret-cli completion for bash. Load it in ~/.bashrc:')
      ..writeln('#   source <(ferret-cli completion bash)')
      ..writeln()
      ..writeln('_ferret_cli_devices() {')
      ..writeln('  local name')
      ..writeln('  while IFS= read -r name; do')
      ..writeln(
        r'    [[ $name == "$cur"* ]] && COMPREPLY+=("$(printf %q "$name")")',
      )
      ..writeln('  done < <(ferret-cli devices --names 2>/dev/null)')
      ..writeln('}')
      ..writeln()
      ..writeln('_ferret_cli() {')
      ..writeln(r'  local cur="${COMP_WORDS[COMP_CWORD]}"')
      ..writeln(r'  local prev="${COMP_WORDS[COMP_CWORD-1]}"')
      ..writeln('  COMPREPLY=()')
      ..writeln(r'  if [[ $COMP_CWORD -eq 1 ]]; then')
      ..writeln(_words('${commands.join(' ')} --help --version'))
      ..writeln('    return')
      ..writeln('  fi')
      ..writeln()
      ..writeln(r'  case "$prev" in')
      ..writeln('    --to) _ferret_cli_devices; return ;;')
      ..writeln(
        '    --type) ${_wordsInline(CompletionSpec.eventTypes.join(' '))}; '
        'return ;;',
      )
      ..writeln('  esac')
      ..writeln()
      ..writeln(r'  case "${COMP_WORDS[1]}" in');

    for (final command in spec.commands) {
      buffer.writeln('    ${command.name})');
      _writeCommand(buffer, command, position: 2, names: commands);
      buffer.writeln('      ;;');
    }

    buffer
      ..writeln('  esac')
      ..writeln('}')
      ..writeln()
      ..writeln('complete -o default -F _ferret_cli ferret-cli');
    return '$buffer';
  }

  static void _writeCommand(
    StringBuffer buffer,
    CompletionEntry command, {
    required int position,
    required List<String> names,
  }) {
    final options = [for (final option in command.options) '--${option.name}'];
    buffer
      ..writeln(r'      if [[ $cur == -* ]]; then')
      ..writeln('  ${_words(options.join(' '))}')
      ..writeln('        return')
      ..writeln('      fi');

    if (command.subcommands.isNotEmpty) {
      final subcommands = [
        for (final subcommand in command.subcommands) subcommand.name,
      ];
      buffer
        ..writeln('      if [[ \$COMP_CWORD -eq $position ]]; then')
        ..writeln('  ${_words(subcommands.join(' '))}')
        ..writeln('        return')
        ..writeln('      fi')
        ..writeln('      case "\${COMP_WORDS[$position]}" in');
      for (final subcommand in command.subcommands) {
        final options = [
          for (final option in subcommand.options) '--${option.name}',
        ];
        buffer
          ..writeln('        ${subcommand.name})')
          ..writeln(
            '          [[ \$cur == -* ]] && '
            '${_wordsInline(options.join(' '))} ;;',
          );
      }
      buffer.writeln('      esac');
      return;
    }

    final first = switch (command.argument) {
      CompletionValue.device => '_ferret_cli_devices',
      CompletionValue.command => _wordsInline(names.join(' ')),
      CompletionValue.shell => _wordsInline(CompletionSpec.shells.join(' ')),
      _ => null,
    };
    if (first != null) {
      buffer.writeln('      [[ \$COMP_CWORD -eq $position ]] && $first');
    }
  }

  static String _words(String words) => '    ${_wordsInline(words)}';

  static String _wordsInline(String words) =>
      'COMPREPLY=(\$(compgen -W "$words" -- "\$cur"))';
}
