import 'dart:typed_data';

/// Bytes from a hex string, with spaces and line breaks allowed.
Uint8List hex(String text) {
  final digits = text.replaceAll(RegExp(r'\s'), '');
  return Uint8List.fromList([
    for (var index = 0; index < digits.length; index += 2)
      int.parse(digits.substring(index, index + 2), radix: 16),
  ]);
}

Uint8List joined(List<List<int>> parts) =>
    Uint8List.fromList([for (final part in parts) ...part]);

/// What scrcpy 5.0.1's server sent an Android 15 emulator's viewer first,
/// captured from the video socket: the dummy byte, the device name, the
/// codec id, a session packet (576x1280) and the config packet.
final Uint8List emulatorHandshake = hex('''
  00
  73646b5f6770686f6e6536345f61726d3634000000000000000000000000000000000000
  00000000000000000000000000000000000000000000000000000000
  68323634
  800000000000024000000500
  400000000000000000000020
  000000016742c0298d680900a1a420202020f08846a00000000168ce01a835c8
''');

final Uint8List emulatorSps = hex('6742c0298d680900a1a420202020f08846a0');
final Uint8List emulatorPps = hex('68ce01a835c8');

/// The header the same server put before its first keyframe (26693 bytes)
/// and before the picture after it (180 bytes).
final Uint8List emulatorKeyframeHeader = hex('200000001ec5942000006845');
final Uint8List emulatorDeltaHeader = hex('000000001ec71ac0000000b4');

/// A media packet header as the server writes it.
Uint8List mediaHeader({
  required int ptsUs,
  required int length,
  bool isConfig = false,
  bool isKeyframe = false,
}) {
  var first = ptsUs;
  if (isConfig) {
    first = 1 << 62;
  }
  if (isKeyframe) {
    first |= 1 << 61;
  }

  final header = ByteData(12)
    ..setUint64(0, first)
    ..setUint32(8, length);
  return header.buffer.asUint8List();
}

Uint8List sessionHeader(int width, int height) {
  final header = ByteData(12)
    ..setUint8(0, 0x80)
    ..setUint32(4, width)
    ..setUint32(8, height);
  return header.buffer.asUint8List();
}
