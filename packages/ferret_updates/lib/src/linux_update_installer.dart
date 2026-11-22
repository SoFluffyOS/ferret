import 'dart:io';

import 'package:ferret_updates/src/update_installer.dart';
import 'package:path/path.dart' as p;

/// Replaces the running AppImage (`$APPIMAGE`, the install script puts it
/// in `~/.local/opt/ferret/Ferret.AppImage`) with the downloaded one.
///
/// The new file is copied next to the old one and renamed over it, which
/// is atomic: the running Ferret keeps its mounted copy until it quits, and
/// a helper then starts the new one. An AppImage carries no signature the
/// system checks, so the SHA256SUMS check before this is what vouches for
/// it.
class LinuxUpdateInstaller implements UpdateInstaller {
  LinuxUpdateInstaller({
    required this.appImage,
    int? processId,
    RunProcess? run,
    StartDetached? detached,
  }) : _pid = processId ?? pid,
       _run = run ?? runProcess,
       _detached = detached ?? startDetached;

  /// The running AppImage's path.
  final String appImage;
  final int _pid;
  final RunProcess _run;
  final StartDetached _detached;

  @override
  Future<InstallOutcome> install(File file) async {
    final staged = p.join(p.dirname(appImage), '.Ferret.AppImage.update-$_pid');
    await file.copy(staged);
    try {
      final executable = await _run('chmod', ['755', staged]);
      if (executable.exitCode != 0) {
        throw StateError('Could not make the update executable');
      }

      await File(staged).rename(appImage);
    } on Object {
      try {
        await File(staged).delete();
      } on FileSystemException {
        // Already gone.
      }
      rethrow;
    }

    await _detached('/bin/sh', [
      '-c',
      r'while kill -0 "$1" 2>/dev/null; do sleep 0.2; done; exec "$2"',
      'ferret-relaunch',
      '$_pid',
      appImage,
    ]);
    return .quitToRestart;
  }
}
