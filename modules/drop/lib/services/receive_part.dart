import 'dart:io';

import 'package:drop/models/models.dart';
import 'package:drop/services/file_hasher.dart';

/// What a file arriving becomes once saved: its safe name, its type, and
/// the folder inside the receive folder it goes to (null for a file sent
/// on its own).
typedef PartTarget = ({String name, String mime, String? folder});

/// One file while it arrives. Bytes are written in order from the start;
/// after a dropped session it opens again where it stopped.
abstract interface class ReceivePart {
  /// Bytes in it now; 0 when nothing was written yet or it is gone.
  Future<int> length();

  /// Opens it to write after its first [offset] bytes, cutting off the
  /// rest. With nothing there yet, [offset] is 0 and it starts empty.
  Future<PartWriter> open(int offset);

  /// SHA-256 of what it holds, read back.
  Future<List<int>> hash();

  /// Puts it in its final place once it checked out, never overwriting a
  /// file that is there. [modified] is kept where the platform allows.
  Future<ReceivedFile> save({DateTime? modified});

  /// Throws away what arrived, such as after a cancel.
  Future<void> delete();
}

/// Appends to a [ReceivePart].
abstract interface class PartWriter {
  Future<void> write(List<int> bytes);

  Future<void> close();
}

/// A part in a plain file, saved by [onSave] (a move or a copy).
class FilePart implements ReceivePart {
  FilePart(this.file, {required this.onSave});

  final File file;
  final Future<ReceivedFile> Function(File part, {DateTime? modified}) onSave;

  @override
  Future<int> length() async => switch (await file.exists()) {
    true => await file.length(),
    false => 0,
  };

  @override
  Future<PartWriter> open(int offset) async {
    final open = await file.open(mode: FileMode.append);
    if (await open.length() != offset) {
      await open.truncate(offset);
      await open.setPosition(offset);
    }

    return _FileWriter(open);
  }

  @override
  Future<List<int>> hash() async {
    if (!await file.exists()) {
      await file.create();
    }

    return FileHasher.hashFile(file.path);
  }

  @override
  Future<ReceivedFile> save({DateTime? modified}) =>
      onSave(file, modified: modified);

  @override
  Future<void> delete() async {
    try {
      await file.delete();
    } on FileSystemException {
      return;
    }
  }
}

class _FileWriter implements PartWriter {
  _FileWriter(this._file);

  final RandomAccessFile _file;

  @override
  Future<void> write(List<int> bytes) => _file.writeFrom(bytes);

  @override
  Future<void> close() => _file.close();
}
