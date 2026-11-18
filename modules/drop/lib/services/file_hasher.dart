import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// SHA-256 of files, computed off the UI isolate.
abstract final class FileHasher {
  /// Hashes the whole file at [path] in a background isolate.
  static Future<List<int>> hashFile(String path) =>
      Isolate.run(() => _hash(path));

  static Future<List<int>> _hash(String path) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.bytes;
  }

  static bool same(List<int> first, List<int> second) {
    if (first.length != second.length) {
      return false;
    }

    var difference = 0;
    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }

    return difference == 0;
  }
}
