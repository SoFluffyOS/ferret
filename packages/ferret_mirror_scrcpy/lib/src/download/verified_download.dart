import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ferret_mirror_scrcpy/src/download/download_exception.dart';
import 'package:ferret_mirror_scrcpy/src/download/pinned_file.dart';
import 'package:path/path.dart' as p;

/// Fetches pinned files over HTTPS and keeps them only when their SHA-256
/// is the pinned one.
class VerifiedDownload {
  VerifiedDownload({HttpClient Function()? createClient})
    : _createClient = createClient ?? HttpClient.new;

  final HttpClient Function() _createClient;

  /// The file in [directory], fetched first when it isn't there yet or no
  /// longer has the pinned hash. Throws a [DownloadException] otherwise.
  Future<File> ensure(PinnedFile pinned, Directory directory) async {
    final target = File(p.join(directory.path, pinned.fileName));
    if (await target.exists() && await _hashOf(target) == pinned.sha256) {
      return target;
    }

    await directory.create(recursive: true);
    final partial = File('${target.path}.part');
    await _fetch(pinned, partial);

    final hash = await _hashOf(partial);
    if (hash != pinned.sha256) {
      await partial.delete();
      throw DownloadException(
        '${pinned.fileName} has SHA-256 $hash, expected ${pinned.sha256}',
      );
    }

    return partial.rename(target.path);
  }

  Future<void> _fetch(PinnedFile pinned, File partial) async {
    final client = _createClient();
    try {
      final request = await client.getUrl(Uri.parse(pinned.url));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw DownloadException(
          '${pinned.url} answered ${response.statusCode}',
        );
      }

      await response.pipe(partial.openWrite());
    } on IOException catch (error) {
      throw DownloadException('Could not fetch ${pinned.url}: $error');
    } finally {
      client.close(force: true);
    }
  }

  static Future<String> _hashOf(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
