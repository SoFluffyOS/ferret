import 'dart:io';

import 'package:drop/models/models.dart';
import 'package:drop/services/services.dart';
import 'package:ferret_drop/ferret_drop.dart';

/// A file arriving straight into `Download/<folder>`: a pending MediaStore
/// item, hidden from other apps, made on the first write and shown only by
/// [save] once its checksum matched. There is no copy at the end and no
/// second file's worth of room.
class MediaStorePart implements ReceivePart {
  MediaStorePart(
    this._downloads, {
    required this.folder,
    required this.name,
    required this.mime,
  });

  final PendingDownloads _downloads;

  /// The path inside Downloads, such as `Ferret/Photos`.
  final String folder;
  final String name;
  final String mime;
  String? _uri;

  @override
  Future<int> length() async {
    final uri = _uri;
    if (uri == null) {
      return 0;
    }

    final size = await _downloads.size(uri);
    if (size == null) {
      _uri = null;
      return 0;
    }

    return size;
  }

  @override
  Future<PartWriter> open(int offset) async {
    if (_uri case final uri?) {
      if (await _downloads.open(uri, offset) case final writer?) {
        return _PendingPartWriter(writer);
      }

      _uri = null;
    }

    if (offset != 0) {
      throw FileSystemException('The file arriving left Downloads', name);
    }

    final created = await _downloads.create(
      folder: folder,
      name: name,
      mime: mime,
    );
    _uri = created.uri;
    return _PendingPartWriter(created.writer);
  }

  @override
  Future<List<int>> hash() async {
    if (_uri == null) {
      await (await open(0)).close();
    }

    return _downloads.sha256(_uri!);
  }

  @override
  Future<ReceivedFile> save({DateTime? modified}) async {
    final uri = _uri;
    if (uri == null) {
      throw FileSystemException('The file arriving left Downloads', name);
    }

    final saved = await _downloads.publish(uri);
    _uri = null;
    return ReceivedFile(
      location: saved.location,
      name: switch (saved.name.isEmpty) {
        true => name,
        false => saved.name,
      },
    );
  }

  @override
  Future<void> delete() async {
    final uri = _uri;
    _uri = null;
    if (uri == null) {
      return;
    }

    try {
      await _downloads.delete(uri);
    } on FileSystemException {
      return;
    }
  }
}

class _PendingPartWriter implements PartWriter {
  _PendingPartWriter(this._writer);

  final PendingWriter _writer;

  @override
  Future<void> write(List<int> bytes) => _writer.write(bytes);

  @override
  Future<void> close() => _writer.close();
}
