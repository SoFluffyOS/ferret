import 'dart:typed_data';

/// A mirroring stream packet as a phone sends it: the 128-byte header and
/// its payload.
Uint8List mirrorPacket({
  required int type,
  required List<int> payload,
  int timestamp = 0,
  int option = 0,
  int width = 0,
  int height = 0,
  int sourceWidth = 0,
  int sourceHeight = 0,
}) {
  final header = ByteData(128)
    ..setUint32(0, payload.length, Endian.little)
    ..setUint8(4, type)
    ..setUint16(6, option, Endian.little)
    ..setUint64(8, timestamp, Endian.little)
    ..setFloat32(16, sourceWidth.toDouble(), Endian.little)
    ..setFloat32(20, sourceHeight.toDouble(), Endian.little)
    ..setFloat32(40, sourceWidth.toDouble(), Endian.little)
    ..setFloat32(44, sourceHeight.toDouble(), Endian.little)
    ..setFloat32(56, width.toDouble(), Endian.little)
    ..setFloat32(60, height.toDouble(), Endian.little);
  return Uint8List.fromList([...header.buffer.asUint8List(), ...payload]);
}

const sampleSps = [0x67, 0x64, 0x00, 0x1f, 0xac, 0xd9, 0x40, 0x50, 0x05, 0xbb];
const samplePps = [0x68, 0xeb, 0xe3, 0xcb, 0x22, 0xc0];

/// An avcC record holding one SPS and one PPS.
Uint8List avccRecord({
  List<int> sps = sampleSps,
  List<int> pps = samplePps,
}) => Uint8List.fromList([
  1, 0x64, 0x00, 0x1f, 0xff, 0xe1, //
  sps.length >> 8, sps.length & 0xff, ...sps,
  1, pps.length >> 8, pps.length & 0xff, ...pps,
]);

/// NAL units each behind a 4-byte big-endian length.
Uint8List lengthPrefixed(List<List<int>> units) => Uint8List.fromList([
  for (final unit in units) ...[
    unit.length >> 24 & 0xff,
    unit.length >> 16 & 0xff,
    unit.length >> 8 & 0xff,
    unit.length & 0xff,
    ...unit,
  ],
]);

/// NAL units each behind a 4-byte start code.
Uint8List annexB(List<List<int>> units) => Uint8List.fromList([
  for (final unit in units) ...[0, 0, 0, 1, ...unit],
]);
