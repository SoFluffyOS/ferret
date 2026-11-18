import 'dart:io';

import 'package:interop_quickshare/models/models.dart';

/// One announced file while its chunks arrive.
class IncomingFile {
  IncomingFile(this.file);

  final QuickShareFile file;
  File? part;
  RandomAccessFile? _handle;
  int received = 0;
  bool isDone = false;

  /// Opens [target] for writing, replacing what an earlier attempt left.
  Future<void> open(File target) async {
    part = target;
    _handle = await target.open(mode: FileMode.write);
  }

  bool get isOpen => _handle != null;

  Future<void> write(List<int> bytes) async {
    await _handle?.writeFrom(bytes);
    received += bytes.length;
  }

  Future<void> close() async {
    final handle = _handle;
    _handle = null;
    await handle?.close();
  }
}
