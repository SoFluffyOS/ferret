import 'dart:io';

import 'package:flutter/services.dart';

/// The short ring tone bundled with the plugin, for platforms that play it
/// from a file.
class RingSound {
  const RingSound._();

  static const asset = 'packages/ferret_find/assets/ring.wav';
  static const _fileName = 'ferret_find_ring.wav';

  /// Writes the tone into [directory] (the system temp folder by default)
  /// once, and returns the file's path.
  static Future<String> file({
    AssetBundle? bundle,
    Directory? directory,
  }) async {
    final folder = directory ?? Directory.systemTemp;
    final target = File('${folder.path}${Platform.pathSeparator}$_fileName');
    final data = await (bundle ?? rootBundle).load(asset);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    if (await target.exists() && await target.length() == bytes.length) {
      return target.path;
    }

    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }
}
