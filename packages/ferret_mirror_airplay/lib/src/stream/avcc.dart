import 'dart:typed_data';

/// H.264 as AirPlay carries it: the avcC decoder configuration, and
/// pictures whose NAL units each start with a 4-byte length.
abstract final class Avcc {
  static const _startCode = [0, 0, 0, 1];
  static const _idrSlice = 5;

  /// The first SPS and PPS of an avcC record, each without a start code.
  /// Null when [config] isn't a complete avcC record.
  static ({Uint8List sps, Uint8List pps})? parameterSets(Uint8List config) {
    if (config.length < 8 || config[0] != 1) {
      return null;
    }

    final spsCount = config[5] & 0x1f;
    if (spsCount < 1) {
      return null;
    }

    var offset = 6;
    Uint8List? sps;
    for (var index = 0; index < spsCount; index++) {
      final unit = _unit(config, offset);
      if (unit == null) {
        return null;
      }

      sps ??= unit;
      offset += 2 + unit.length;
    }

    if (offset >= config.length || config[offset] < 1) {
      return null;
    }

    final pps = _unit(config, offset + 1);
    if (sps == null || pps == null || sps.isEmpty || pps.isEmpty) {
      return null;
    }

    return (sps: sps, pps: pps);
  }

  /// Whether [config] describes H.265 (an `hvc1` box) instead of H.264.
  static bool isHevc(Uint8List config) =>
      config.length >= 8 &&
      config[4] == 0x68 &&
      config[5] == 0x76 &&
      config[6] == 0x63 &&
      config[7] == 0x31;

  /// Rewrites length-prefixed NAL units as one Annex-B access unit, and
  /// says whether it holds a keyframe. Null when the lengths don't add up,
  /// which is what a wrong decryption key looks like.
  static ({Uint8List data, bool keyframe})? toAnnexB(Uint8List payload) {
    final out = Uint8List(payload.length);
    final view = ByteData.sublistView(payload);
    var offset = 0;
    var keyframe = false;
    while (offset < payload.length) {
      if (payload.length - offset < 5) {
        return null;
      }

      final length = view.getUint32(offset);
      final start = offset + 4;
      if (length < 1 || length > payload.length - start) {
        return null;
      }

      final header = payload[start];
      if (header & 0x80 != 0) {
        return null;
      }

      if (header & 0x1f == _idrSlice) {
        keyframe = true;
      }

      out
        ..setRange(offset, start, _startCode)
        ..setRange(start, start + length, payload, start);
      offset = start + length;
    }

    if (offset == 0) {
      return null;
    }

    return (data: out, keyframe: keyframe);
  }

  /// A unit with a 2-byte big-endian length in front, at [offset].
  static Uint8List? _unit(Uint8List bytes, int offset) {
    if (offset + 2 > bytes.length) {
      return null;
    }

    final length = bytes[offset] << 8 | bytes[offset + 1];
    final start = offset + 2;
    if (start + length > bytes.length) {
      return null;
    }

    return Uint8List.sublistView(bytes, start, start + length);
  }
}
