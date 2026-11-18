import 'dart:typed_data';

/// Bytes as they come off a socket, read back in the sizes a protocol asks
/// for, whatever the sizes they arrived in.
class ByteQueue {
  final BytesBuilder _pending = .new(copy: false);

  int get length => _pending.length;

  void add(List<int> chunk) => _pending.add(chunk);

  /// The next [count] bytes, or null while fewer have arrived.
  Uint8List? take(int count) {
    if (_pending.length < count) {
      return null;
    }

    final all = _pending.takeBytes();
    if (all.length > count) {
      _pending.add(Uint8List.sublistView(all, count));
    }

    return Uint8List.sublistView(all, 0, count);
  }

  /// Everything that arrived and wasn't read yet.
  Uint8List takeAll() => _pending.takeBytes();
}
