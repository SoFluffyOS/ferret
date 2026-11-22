import 'dart:io';

import 'package:ferret_updates/src/update_installer.dart';
import 'package:path/path.dart' as p;

/// Installs a Mac update from the release's DMG.
///
/// It mounts the DMG read-only and checks the Ferret.app inside: a valid,
/// complete signature (`codesign --verify --deep --strict`) by Ferret's
/// Developer ID team, for Ferret's bundle id, that Gatekeeper accepts as
/// notarized (`spctl`). Then it copies the app next to the running one,
/// checks the copy again, and swaps the two by renaming, so a failure half
/// way leaves the old app whole. A helper waits for Ferret to quit, removes
/// the old app and opens the new one.
///
/// Without write access to the app's folder (a standard account and Ferret
/// in /Applications) or when macOS runs Ferret from a translocated copy, it
/// opens the checked DMG in Finder for a drag, as a first install does,
/// rather than asking for an administrator's password.
class MacUpdateInstaller implements UpdateInstaller {
  MacUpdateInstaller({
    String? executable,
    int? processId,
    RunProcess? run,
    StartDetached? detached,
    Future<Directory> Function()? scratch,
    Future<bool> Function(String folder)? canWrite,
  }) : _executable = executable ?? Platform.resolvedExecutable,
       _pid = processId ?? pid,
       _run = run ?? runProcess,
       _detached = detached ?? startDetached,
       _scratch =
           scratch ?? (() => Directory.systemTemp.createTemp('ferret-update-')),
       _canWrite = canWrite ?? _folderIsWritable;

  /// Ferret's Developer ID team.
  static const teamId = '66UZUS2MST';
  static const bundleId = 'io.sofluffy.ferret';

  final String _executable;
  final int _pid;
  final RunProcess _run;
  final StartDetached _detached;
  final Future<Directory> Function() _scratch;
  final Future<bool> Function(String folder) _canWrite;

  /// Ferret.app, from `Ferret.app/Contents/MacOS/ferret`.
  String get currentApp => p.dirname(p.dirname(p.dirname(_executable)));

  @override
  Future<InstallOutcome> install(File file) async {
    final target = currentApp;
    if (!target.endsWith('.app')) {
      throw StateError('Not running from an app bundle: $target');
    }

    final mountPoint = (await _scratch()).path;
    final attach = await _run('hdiutil', [
      'attach',
      '-nobrowse',
      '-readonly',
      '-noautoopen',
      '-mountpoint',
      mountPoint,
      file.path,
    ]);
    if (attach.exitCode != 0) {
      throw StateError('Could not mount the update: ${attach.stderr}');
    }

    try {
      final source = await _appIn(mountPoint);
      await verify(source);

      final folder = p.dirname(target);
      final translocated = target.contains('/AppTranslocation/');
      if (translocated || !await _canWrite(folder)) {
        await _run('hdiutil', ['detach', '-force', mountPoint]);
        await _run('open', [file.path]);
        return .openedForYou;
      }

      final staged = p.join(folder, '.Ferret-update-$_pid.app');
      final old = p.join(folder, '.Ferret-old-$_pid.app');
      final copy = await _run('ditto', [source, staged]);
      if (copy.exitCode != 0) {
        throw StateError('Could not copy the update: ${copy.stderr}');
      }

      try {
        await verify(staged);
      } on Object {
        await _remove(staged);
        rethrow;
      }

      await _swap(target: target, staged: staged, old: old);
      await _detached('/bin/sh', [
        '-c',
        r'while kill -0 "$1" 2>/dev/null; do sleep 0.2; done; '
            r'rm -rf "$3"; open "$2"',
        'ferret-relaunch',
        '$_pid',
        target,
        old,
      ]);
      return .quitToRestart;
    } finally {
      await _run('hdiutil', ['detach', '-force', mountPoint]);
    }
  }

  /// Refuses [app] unless it is Ferret, signed by [teamId] and notarized.
  Future<void> verify(String app) async {
    final strict = await _run('codesign', [
      '--verify',
      '--deep',
      '--strict',
      app,
    ]);
    if (strict.exitCode != 0) {
      throw UpdateRefused(.notSigned, '${strict.stderr}');
    }

    final details = await _run('codesign', ['-dv', '--verbose=2', app]);
    final info = '${details.stdout}\n${details.stderr}';
    final lines = info.split('\n').map((line) => line.trim()).toSet();
    if (!lines.contains('TeamIdentifier=$teamId') ||
        !lines.contains('Identifier=$bundleId') ||
        !lines.any(
          (line) => line.startsWith('Authority=Developer ID Application:'),
        )) {
      throw UpdateRefused(.wrongPublisher, info);
    }

    final gatekeeper = await _run('spctl', [
      '--assess',
      '--type',
      'execute',
      '-vv',
      app,
    ]);
    final verdict = '${gatekeeper.stdout}\n${gatekeeper.stderr}';
    if (gatekeeper.exitCode != 0 ||
        !verdict.contains('source=Notarized Developer ID')) {
      throw UpdateRefused(.notNotarized, verdict);
    }
  }

  Future<String> _appIn(String mountPoint) async {
    final ferret = p.join(mountPoint, 'Ferret.app');
    if (await Directory(ferret).exists()) {
      return ferret;
    }

    await for (final entity in Directory(mountPoint).list()) {
      if (entity is Directory && entity.path.endsWith('.app')) {
        return entity.path;
      }
    }

    throw StateError('No app in the update');
  }

  Future<void> _swap({
    required String target,
    required String staged,
    required String old,
  }) async {
    await Directory(target).rename(old);
    try {
      await Directory(staged).rename(target);
    } on Object {
      await Directory(old).rename(target);
      await _remove(staged);
      rethrow;
    }
  }

  Future<void> _remove(String path) async {
    try {
      await Directory(path).delete(recursive: true);
    } on FileSystemException {
      // Left in a hidden folder name; the next update uses another one.
    }
  }

  static Future<bool> _folderIsWritable(String folder) async {
    final probe = File(p.join(folder, '.ferret-write-$pid'));
    try {
      await probe.writeAsString('');
      await probe.delete();
      return true;
    } on FileSystemException {
      return false;
    }
  }
}
