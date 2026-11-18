import 'dart:typed_data';
import 'dart:ui' as ui;

/// Keeps album art small enough to send in one media message.
abstract final class ArtworkShrinker {
  static const maxBytes = 64 * 1024;
  static const _sides = [256, 160, 96];

  /// Returns [bytes] when they already fit, a smaller PNG otherwise, or null
  /// when the image can't be read or shrunk enough.
  static Future<Uint8List?> shrink(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return null;
    }

    if (bytes.length <= maxBytes && _isJpegOrPng(bytes)) {
      return bytes;
    }

    for (final side in _sides) {
      final encoded = await _encode(bytes, side);
      if (encoded == null) {
        return null;
      }

      if (encoded.length <= maxBytes) {
        return encoded;
      }
    }

    return null;
  }

  static bool _isJpegOrPng(Uint8List bytes) {
    if (bytes.length < 4) {
      return false;
    }

    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
    final isPng =
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    return isJpeg || isPng;
  }

  static Future<Uint8List?> _encode(Uint8List bytes, int side) async {
    try {
      final codec = await ui.instantiateImageCodecWithSize(
        await ui.ImmutableBuffer.fromUint8List(bytes),
        getTargetSize: (width, height) {
          final longest = switch (width > height) {
            true => width,
            false => height,
          };
          if (longest <= side) {
            return ui.TargetImageSize(width: width, height: height);
          }

          final scale = side / longest;
          return ui.TargetImageSize(
            width: (width * scale).round(),
            height: (height * scale).round(),
          );
        },
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: .png);
      frame.image.dispose();
      codec.dispose();
      return data?.buffer.asUint8List();
    } on Object {
      return null;
    }
  }
}
