import 'dart:io';

import 'package:drop/drop.dart';
import 'package:feature_kit/feature_kit.dart';

/// `ferret send <file>…`, which a file manager's "Send with Ferret" entry
/// runs: the files go to the Ferret that is already running, or this run
/// starts up and sends them itself. On Windows and Linux a plain second
/// launch shows the running Ferret's window and ends.
class SendCommand {
  const SendCommand._(this.files, this.handoff);

  /// The files this run should send once it is up.
  final List<String> files;

  /// Takes the files of later runs. Null on phones, where the system's
  /// share sheet does this job.
  final SendHandoff? handoff;

  /// Reads [arguments]. Never returns when a running Ferret took the files:
  /// this run ends there, before it shows anything.
  static Future<SendCommand> read(List<String> arguments) async {
    final isComputer =
        Platform.isLinux || Platform.isWindows || Platform.isMacOS;
    if (!isComputer) {
      return const SendCommand._([], null);
    }

    final files = SendArguments.paths(arguments);
    final paths = await AppPaths.get();
    final handoff = SendHandoff(paths.root);
    if (await handoff.handOver(files)) {
      exit(0);
    }

    // Windows and Linux start a second Ferret on every launch; the first
    // one, maybe hidden in the tray, shows its window instead.
    final wakes = Platform.isLinux || Platform.isWindows;
    if (wakes && files.isEmpty && await handoff.wakeUp()) {
      exit(0);
    }

    return SendCommand._(files, handoff);
  }
}
