import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drop/services/outgoing_file.dart';
import 'package:ferret_drop/ferret_drop.dart';
import 'package:mime/mime.dart';

/// One file to send, opened at its first byte.
abstract interface class SendReader {
  /// Its size now, or null when the source can't say.
  Future<int?> length();

  /// Up to [max] next bytes; empty at the end.
  Future<Uint8List> read(int max);

  Future<void> close();
}

/// Where files to send are read from: a path on disk, or on Android a
/// `content://` URI another app shared or the picker returned, read
/// straight from that app with nothing copied first.
class SendSources {
  const SendSources({ContentSource content = const ContentFiles()})
    : _content = content;

  final ContentSource _content;

  static bool isContent(String location) => ContentFiles.isContent(location);

  /// Describes [location], or null when it can't be sent: missing, not a
  /// file, or no longer readable. A URI whose app doesn't say how big it
  /// is gets copied into the cache, and the copy goes instead.
  Future<OutgoingFile?> describe(String location, {String? folder}) async {
    if (!isContent(location)) {
      return OutgoingFile.fromPath(location, folder: folder);
    }

    final info = await _content.describe(location);
    if (info == null) {
      return null;
    }

    if (info.size < 0) {
      final copy = await _content.copy(location);
      return switch (copy) {
        final path? => OutgoingFile.fromPath(path, folder: folder),
        null => null,
      };
    }

    return OutgoingFile(
      path: location,
      name: info.name,
      size: info.size,
      mime: switch (info.mime) {
        '' => lookupMimeType(info.name) ?? '',
        final mime => mime,
      },
      folder: folder,
      modified: info.modified,
    );
  }

  /// Opens [location] at its first byte. Throws [FileSystemException]
  /// when it can't be read.
  Future<SendReader> open(String location) async {
    if (isContent(location)) {
      return _ContentSendReader(await _content.open(location));
    }

    return _FileSendReader(await File(location).open());
  }

  /// [location]'s bytes as a stream, for senders that take one.
  Stream<List<int>> openRead(String location) async* {
    if (!isContent(location)) {
      yield* File(location).openRead();
      return;
    }

    final reader = await _content.open(location);
    try {
      while (true) {
        final bytes = await reader.read(256 * 1024);
        if (bytes.isEmpty) {
          return;
        }

        yield bytes;
      }
    } finally {
      await reader.close();
    }
  }

  /// Done with a temporary [location]: a copy is deleted, a URI's
  /// permission to read it let go.
  Future<void> discard(String location) async {
    if (isContent(location)) {
      await _content.release(location);
      return;
    }

    try {
      await File(location).delete();
    } on FileSystemException {
      return;
    }
  }
}

class _FileSendReader implements SendReader {
  _FileSendReader(this._file);

  final RandomAccessFile _file;

  @override
  Future<int?> length() => _file.length();

  @override
  Future<Uint8List> read(int max) => _file.read(max);

  @override
  Future<void> close() => _file.close();
}

class _ContentSendReader implements SendReader {
  _ContentSendReader(this._reader);

  final ContentReader _reader;

  @override
  Future<int?> length() async => _reader.length;

  @override
  Future<Uint8List> read(int max) => _reader.read(max);

  @override
  Future<void> close() => _reader.close();
}
