/// A command running on a device.
class AdbShell {
  AdbShell({
    required this.lines,
    required this.done,
    required void Function() kill,
  }) : _kill = kill;

  /// What the command prints, a line at a time.
  final Stream<String> lines;

  /// Completes when the command ended, or the way to it was lost.
  final Future<void> done;

  final void Function() _kill;

  /// Ends the command by cutting it off from this computer.
  void kill() => _kill();
}
