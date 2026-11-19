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

/// What the same server sent first on its audio socket with
/// `audio_codec=opus`, captured from an Android 15 emulator: the codec id,
/// the config packet (an Opus identification header: stereo, 48 kHz), and
/// two packets of silence, 20 ms each.
final Uint8List emulatorAudioStart = hex('''
  6f707573
  400000000000000000000013
  4f707573486561640102380180bb0000000000
  00000005228c363400000003 fcfffe
  00000005228bfa7c00000003 fcfffe
''');

/// One packet from the middle of the same capture, header first: 20 ms of
/// a 440 Hz tone that was playing on the emulator (334 bytes of Opus).
final Uint8List emulatorTonePacket = hex('''
  00000005229a48970000014efcb2472c78ac94e6d65d7b585a167797f098cebf09dba4a9
  5e89996dcc7e3d045a87a385e264f0ca67501800a5a0a5130f732b7c5225c38a06ea45b4
  b0583e74b234d905b7c67dd6560e4b197f0d44e92ad1fb400f9ed2f2d3462a7d76ae86f7
  45e715310c9863d9fda4818285eebc188a57b90d02b33e464e9b630547deb9b6f21c97b8
  ab55b09d12c1ab40a75d72887f745bd5aec033dcb3385d49c7154a198782db3d4e0f9765
  dc1eb39e063f0ff2aab36f845832c9f333fc1fe3ae84fc20d72a61327e744720f2b8de3a
  d69faf2cab6222e0b66aebe70a0e2de4a64aed74a83b0cd7811be6fcd79727d076d44e61
  65fbd6cbac9b719e0b1f6487c0093f17a6c4b9c3c8ce3ce985348be3010cace68ace4433
  c024d70d323c7416d748d334cf319803f0d9ab7c2f1cd626ab615398653c3ed206a84514
  3333ffe0400dff6c8dc9b25f27ffd54910003181ddae
''');

/// What the audio socket starts with for `audio_codec=raw`, from the same
/// emulator: the codec id, then the header of the first packet of plain
/// samples (4096 bytes: 1024 stereo frames).
final Uint8List emulatorRawAudioStart = hex('''
  00726177
  00000005242ac53c00001000
''');

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
