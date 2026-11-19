/// How a command run by `CommandRunner` ended.
class CommandOutcome {
  const CommandOutcome({
    this.exitCode,
    this.output = '',
    this.timedOut = false,
    this.started = true,
  });

  /// The program couldn't be started, such as when no such file exists.
  /// [output] then says why.
  const CommandOutcome.notStarted(this.output)
    : exitCode = null,
      timedOut = false,
      started = false;

  /// Null when it never started, or was stopped for running too long.
  final int? exitCode;

  /// What it printed, standard output and errors together as they came,
  /// cut to the runner's limit.
  final String output;

  /// It ran past the timeout and was stopped.
  final bool timedOut;

  final bool started;

  bool get succeeded => exitCode == 0;

  /// The last line it printed that says anything, or empty.
  String get lastLine {
    for (final line in output.split('\n').reversed) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return '';
  }
}
