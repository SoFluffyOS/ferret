import 'dart:async';
import 'dart:typed_data';

/// Raised when the other side sends bytes that break the framing.
class FramingException implements Exception {
  const FramingException(this.message);

  final String message;

  @override
  String toString() => 'FramingException: $message';
}

/// Splits a byte stream into frames, each prefixed with a 2-byte big-endian
/// length, as Noise suggests for stream transports.
class FrameReader {
  FrameReader(Stream<Uint8List> input) : _input = StreamIterator(input);

  static const maxFrameLength = 0xffff;

  final StreamIterator<Uint8List> _input;
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);

  /// The next frame, or null when the stream ended cleanly between frames.
  Future<Uint8List?> next() async {
    final header = await _read(2);
    if (header == null) {
      return null;
    }

    final length = (header[0] << 8) | header[1];
    final frame = await _read(length);
    if (frame == null) {
      throw const FramingException('Stream ended inside a frame.');
    }

    return frame;
  }

  Future<void> cancel() => _input.cancel();

  Future<Uint8List?> _read(int length) async {
    while (_pending.length < length) {
      if (!await _input.moveNext()) {
        if (_pending.isEmpty) {
          return null;
        }

        throw const FramingException('Stream ended inside a frame.');
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

/// Prefixes [frame] with its 2-byte length.
Uint8List encodeFrame(List<int> frame) {
  if (frame.length > FrameReader.maxFrameLength) {
    throw ArgumentError.value(
      frame.length,
      'frame',
      'Frame longer than 65535 bytes',
    );
  }

  return Uint8List(frame.length + 2)
    ..[0] = frame.length >> 8
    ..[1] = frame.length & 0xff
    ..setAll(2, frame);
}
