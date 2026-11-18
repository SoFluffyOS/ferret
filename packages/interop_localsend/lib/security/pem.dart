import 'dart:convert';
import 'dart:typed_data';

/// PEM armour around DER bytes.
abstract final class Pem {
  static const certificateLabel = 'CERTIFICATE';
  static const privateKeyLabel = 'PRIVATE KEY';
  static const _lineLength = 64;

  static String encode(String label, List<int> der) {
    final body = base64.encode(der);
    final lines = [
      for (var start = 0; start < body.length; start += _lineLength)
        body.substring(
          start,
          switch (start + _lineLength < body.length) {
            true => start + _lineLength,
            false => body.length,
          },
        ),
    ];
    return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----\n';
  }

  /// The DER bytes of the first PEM block in [pem], or null when there is
  /// none.
  static Uint8List? decode(String pem) {
    final body = [
      for (final line in const LineSplitter().convert(pem))
        if (line.trim().isNotEmpty && !line.startsWith('-----')) line.trim(),
    ].join();
    if (body.isEmpty) {
      return null;
    }

    try {
      return base64.decode(body);
    } on FormatException {
      return null;
    }
  }
}
