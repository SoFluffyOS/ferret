import 'dart:async';
import 'dart:typed_data';

import 'package:interop_quickshare/models/models.dart';

/// Splits a byte stream into Quick Share frames, each prefixed with a
/// 4-byte big-endian length. Bytes are only read when a frame is asked
/// for, so a slow receiver slows the sender down instead of filling
/// memory.
class FrameReader {
  FrameReader(Stream<Uint8List> input, {this.maxFrameLength = 5 * 1024 * 1024})
    : _input = StreamIterator(input);

  /// Longer frames end the connection. File chunks are far smaller.
  final int maxFrameLength;

  final StreamIterator<Uint8List> _input;
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);

  /// The next frame, or null when the stream ended between frames.
  /// Throws a [QuickShareException] when it ends inside one or a frame is
  /// too long.
  Future<Uint8List?> next() async {
    final header = await _read(4);
    if (header == null) {
      return null;
    }

    final length = ByteData.sublistView(header).getUint32(0);
    if (length > maxFrameLength) {
      throw const QuickShareException(.protocol, 'Frame too long');
    }

    final frame = await _read(length);
    if (frame == null) {
      throw const QuickShareException(.unreachable, 'Ended inside a frame');
    }

    return frame;
  }

  Future<void> cancel() async {
    await _input.cancel();
  }

  Future<Uint8List?> _read(int length) async {
    while (_pending.length < length) {
      if (!await _input.moveNext()) {
        if (_pending.isEmpty) {
          return null;
        }

        throw const QuickShareException(.unreachable, 'Ended inside a frame');
      }

      _buffer
        ..add(_pending)
        ..add(_input.current);
      _pending = _buffer.takeBytes();
    }

    final bytes = Uint8List.sublistView(_pending, 0, length);
    _pending = Uint8List.sublistView(_pending, length);
    return bytes;
  }
}
