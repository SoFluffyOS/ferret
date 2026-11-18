import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ferret_mirror_scrcpy/src/server/scrcpy_release.dart';
import 'package:ferret_mirror_scrcpy/src/server/scrcpy_server_exception.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// scrcpy's server as it ships inside the app. Nothing is downloaded: the
/// file comes out of the app's own assets, and is only used when its
/// SHA-256 is the one scrcpy published for the pinned release.
class ScrcpyServerBundle {
  ScrcpyServerBundle({
    required this.directory,
    Future<ByteData> Function()? load,
  }) : _load = load ?? _loadAsset;

  /// Where the server is written so adb can read it, such as the app's
  /// support folder.
  final Future<Directory> Function() directory;
  final Future<ByteData> Function() _load;

  /// The server as a file on this computer, checked. Throws a
  /// [ScrcpyServerException] when the bundled bytes aren't the pinned ones.
  Future<File> ensure() async {
    final folder = await directory();
    final target = File(p.join(folder.path, ScrcpyRelease.serverFileName));
    if (await target.exists() && _isPinned(await target.readAsBytes())) {
      return target;
    }

    final bundled = await _load();
    final bytes = bundled.buffer.asUint8List(
      bundled.offsetInBytes,
      bundled.lengthInBytes,
    );
    if (!_isPinned(bytes)) {
      throw const ScrcpyServerException(
        'The bundled scrcpy server does not have the pinned SHA-256',
      );
    }

    try {
      await folder.create(recursive: true);
      final partial = File('${target.path}.part');
      await partial.writeAsBytes(bytes, flush: true);
      return await partial.rename(target.path);
    } on FileSystemException catch (error) {
      throw ScrcpyServerException(
        'Could not write the server: ${error.message}',
      );
    }
  }

  static bool _isPinned(Uint8List bytes) =>
      sha256.convert(bytes).toString() == ScrcpyRelease.serverSha256;

  static Future<ByteData> _loadAsset() =>
      rootBundle.load(ScrcpyRelease.serverAsset);
}
