import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:ferret_mirror_scrcpy/src/adb/adb_exception.dart';
import 'package:ferret_mirror_scrcpy/src/adb/platform_tools_release.dart';
import 'package:ferret_mirror_scrcpy/src/download/download.dart';
import 'package:path/path.dart' as p;

/// Puts Google's platform-tools (adb) on this computer, for people who
/// don't have the Android SDK: downloaded from Google, checked against a
/// pinned SHA-256, unpacked next to Ferret's own files.
class AdbInstaller {
  AdbInstaller({
    required this.directory,
    VerifiedDownload? download,
    String? operatingSystem,
  }) : _download = download ?? VerifiedDownload(),
       _operatingSystem = operatingSystem ?? Platform.operatingSystem;

  /// The folder that holds the downloads, such as the app's support folder.
  final Future<Directory> Function() directory;
  final VerifiedDownload _download;
  final String _operatingSystem;

  String get _executableName {
    if (_operatingSystem == 'windows') {
      return 'adb.exe';
    }

    return 'adb';
  }

  /// Where adb's folder is once installed, whether it is there or not.
  Future<String> installDirectory() async {
    final root = await directory();
    return p.join(
      root.path,
      'platform-tools-${PlatformToolsRelease.version}',
      'platform-tools',
    );
  }

  /// Downloads and unpacks adb, and returns its path. Does nothing when it
  /// is already there. Throws a [DownloadException] when the download fails
  /// or isn't the pinned file.
  Future<String> install() async {
    final pinned = PlatformToolsRelease.forSystem(_operatingSystem);
    if (pinned == null) {
      throw const AdbException('No platform-tools for this system');
    }

    final executable = p.join(await installDirectory(), _executableName);
    if (await File(executable).exists()) {
      return executable;
    }

    final root = await directory();
    final archive = await _download.ensure(pinned, root);
    await _unpack(archive, Directory(p.dirname(await installDirectory())));
    await archive.delete();

    return executable;
  }

  /// Unpacks beside the final folder first, so a half-unpacked adb is never
  /// found by the next start.
  Future<void> _unpack(File archive, Directory target) async {
    final unpacking = Directory('${target.path}.unpacking');
    if (await unpacking.exists()) {
      await unpacking.delete(recursive: true);
    }

    await extractFileToDisk(archive.path, unpacking.path);
    await _makeExecutable(p.join(unpacking.path, 'platform-tools'));
    if (await target.exists()) {
      await target.delete(recursive: true);
    }

    await unpacking.rename(target.path);
  }

  Future<void> _makeExecutable(String toolsDirectory) async {
    if (_operatingSystem == 'windows') {
      return;
    }

    final result = await Process.run('chmod', [
      '+x',
      p.join(toolsDirectory, _executableName),
    ]);
    if (result.exitCode != 0) {
      throw AdbException('Could not make adb executable: ${result.stderr}');
    }
  }
}
