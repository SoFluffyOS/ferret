import 'dart:io';

import 'package:ferret_mirror_scrcpy/src/download/download.dart';
import 'package:ferret_mirror_scrcpy/src/server/scrcpy_release.dart';

/// Keeps the pinned scrcpy server on this computer: downloaded once from
/// scrcpy's GitHub release, checked against its published SHA-256.
class ScrcpyServerCache {
  ScrcpyServerCache({required this.directory, VerifiedDownload? download})
    : _download = download ?? VerifiedDownload();

  final Future<Directory> Function() directory;
  final VerifiedDownload _download;

  /// The server's file, downloaded first when needed. Throws a
  /// [DownloadException] when it can't be had.
  Future<File> ensure() async =>
      _download.ensure(ScrcpyRelease.server, await directory());
}
