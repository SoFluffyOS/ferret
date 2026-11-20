import 'package:ferret_cli/completion/completion_value.dart';

/// One `--option` of a command, for completions.
typedef CompletionOption = ({String name, String help, CompletionValue value});

/// One command, its options, what its first word is, and its subcommands.
class CompletionEntry {
  const CompletionEntry({
    required this.name,
    required this.summary,
    required this.options,
    required this.argument,
    required this.subcommands,
  });

  final String name;
  final String summary;
  final List<CompletionOption> options;
  final CompletionValue argument;
  final List<CompletionEntry> subcommands;
}
