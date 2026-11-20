import 'dart:typed_data';

/// ChaCha20-Poly1305 (RFC 8439), synchronous and without extra copies.
///
/// The `cryptography` package's pure-Dart AEAD tops out near 200 Mbit/s on
/// a laptop and far less on a phone, which capped big transfers well below
/// what 5 GHz Wi-Fi carries. This one works on 32-bit words in place and
/// runs Poly1305 on 26-bit limbs, so every product fits a 64-bit int.
/// Same bytes on the wire.
abstract final class ChaChaPoly {
  static const keyLength = 32;
  static const nonceLength = 12;
  static const tagLength = 16;

  static const _mask32 = 0xffffffff;
  static const _mask26 = 0x3ffffff;

  /// [plaintext] encrypted, followed by its 16-byte tag.
  static Uint8List encrypt(
    List<int> key,
    List<int> nonce,
    List<int> associatedData,
    List<int> plaintext,
  ) {
    final state = _state(key, nonce);
    final out = Uint8List(plaintext.length + tagLength)
      ..setRange(0, plaintext.length, plaintext);
    final polyKey = _polyKey(state);
    _xorKeyStream(state, out, plaintext.length, 1);
    final tag = _tag(polyKey, _bytes(associatedData), out, plaintext.length);
    out.setRange(plaintext.length, out.length, tag);
    return out;
  }

  /// The plaintext of [ciphertext] (which ends in its tag), or null when
  /// the tag doesn't match.
  static Uint8List? decrypt(
    List<int> key,
    List<int> nonce,
    List<int> associatedData,
    List<int> ciphertext,
  ) {
    if (ciphertext.length < tagLength) {
      return null;
    }

    final length = ciphertext.length - tagLength;
    final input = _bytes(ciphertext);
    final state = _state(key, nonce);
    final polyKey = _polyKey(state);
    final expected = _tag(polyKey, _bytes(associatedData), input, length);
    var difference = 0;
    for (var index = 0; index < tagLength; index++) {
      difference |= expected[index] ^ input[length + index];
    }

    if (difference != 0) {
      return null;
    }

    final out = Uint8List(length)..setRange(0, length, input);
    _xorKeyStream(state, out, length, 1);
    return out;
  }

  /// Plain ChaCha20: [data] XORed with the key stream from block [counter]
  /// on. The AEAD above uses it from block 1; this entry point is here for
  /// the RFC 8439 test vectors.
  static Uint8List chacha20(
    List<int> key,
    List<int> nonce,
    int counter,
    List<int> data,
  ) {
    final out = Uint8List.fromList(data);
    _xorKeyStream(_state(key, nonce), out, out.length, counter);
    return out;
  }

  /// Plain Poly1305 of [message] under a 32-byte one-time [key], for the
  /// RFC 8439 test vectors.
  static Uint8List poly1305(List<int> key, List<int> message) {
    if (key.length != keyLength) {
      throw ArgumentError('Poly1305 needs a 32-byte key.');
    }

    final words = ByteData.sublistView(_bytes(key));
    final poly = _Poly1305(
      Uint32List.fromList([
        for (var word = 0; word < 8; word++)
          words.getUint32(word * 4, Endian.little),
      ]),
    );
    final bytes = _bytes(message);
    poly.update(bytes, bytes.length, padded: false);
    return poly.finish();
  }

  /// The one-time Poly1305 key the AEAD derives for [key] and [nonce].
  static Uint8List poly1305KeyFor(List<int> key, List<int> nonce) =>
      chacha20(key, nonce, 0, Uint8List(32));

  static Uint8List _bytes(List<int> data) => switch (data) {
    final Uint8List bytes => bytes,
    _ => Uint8List.fromList(data),
  };

  /// The ChaCha20 input block with the block counter at 0.
  static Uint32List _state(List<int> key, List<int> nonce) {
    if (key.length != keyLength || nonce.length != nonceLength) {
      throw ArgumentError('ChaCha20 needs a 32-byte key and a 12-byte nonce.');
    }

    final keyData = ByteData.sublistView(_bytes(key));
    final nonceData = ByteData.sublistView(_bytes(nonce));
    return Uint32List(16)
      ..[0] = 0x61707865
      ..[1] = 0x3320646e
      ..[2] = 0x79622d32
      ..[3] = 0x6b206574
      ..[4] = keyData.getUint32(0, Endian.little)
      ..[5] = keyData.getUint32(4, Endian.little)
      ..[6] = keyData.getUint32(8, Endian.little)
      ..[7] = keyData.getUint32(12, Endian.little)
      ..[8] = keyData.getUint32(16, Endian.little)
      ..[9] = keyData.getUint32(20, Endian.little)
      ..[10] = keyData.getUint32(24, Endian.little)
      ..[11] = keyData.getUint32(28, Endian.little)
      ..[12] = 0
      ..[13] = nonceData.getUint32(0, Endian.little)
      ..[14] = nonceData.getUint32(4, Endian.little)
      ..[15] = nonceData.getUint32(8, Endian.little);
  }

  /// Block 0's first 32 bytes, the one-time Poly1305 key.
  static Uint32List _polyKey(Uint32List state) {
    final block = Uint32List(16);
    state[12] = 0;
    _block(state, block);
    return Uint32List.sublistView(block, 0, 8);
  }

  /// XORs the key stream from block [counter] on into the first [length]
  /// bytes. The 32-bit block counter must not wrap (RFC 8439 section 2.4).
  static void _xorKeyStream(
    Uint32List state,
    Uint8List data,
    int length,
    int counter,
  ) {
    final blocks = (length + 63) ~/ 64;
    if (counter < 0 || counter + blocks - 1 > _mask32) {
      throw ArgumentError('The ChaCha20 block counter would wrap.');
    }

    final block = Uint32List(16);
    final blockBytes = Uint8List.view(block.buffer);
    final view = ByteData.sublistView(data);
    var offset = 0;
    while (offset < length) {
      state[12] = counter++;
      _block(state, block);
      if (Endian.host != Endian.little) {
        for (var word = 0; word < 16; word++) {
          final value = block[word];
          blockBytes
            ..[word * 4] = value
            ..[word * 4 + 1] = value >> 8
            ..[word * 4 + 2] = value >> 16
            ..[word * 4 + 3] = value >> 24;
        }
      }

      if (length - offset >= 64) {
        for (var word = 0; word < 16; word++) {
          final at = offset + word * 4;
          view.setUint32(
            at,
            view.getUint32(at, Endian.little) ^ block[word],
            Endian.little,
          );
        }

        offset += 64;
        continue;
      }

      for (var index = 0; offset < length; index++, offset++) {
        data[offset] ^= blockBytes[index];
      }
    }
  }

  static int _rotl(int value, int bits) =>
      ((value << bits) | (value >> (32 - bits))) & _mask32;

  static void _block(Uint32List input, Uint32List output) {
    var x0 = input[0];
    var x1 = input[1];
    var x2 = input[2];
    var x3 = input[3];
    var x4 = input[4];
    var x5 = input[5];
    var x6 = input[6];
    var x7 = input[7];
    var x8 = input[8];
    var x9 = input[9];
    var x10 = input[10];
    var x11 = input[11];
    var x12 = input[12];
    var x13 = input[13];
    var x14 = input[14];
    var x15 = input[15];

    for (var round = 0; round < 10; round++) {
      x0 = (x0 + x4) & _mask32;
      x12 = _rotl(x12 ^ x0, 16);
      x8 = (x8 + x12) & _mask32;
      x4 = _rotl(x4 ^ x8, 12);
      x0 = (x0 + x4) & _mask32;
      x12 = _rotl(x12 ^ x0, 8);
      x8 = (x8 + x12) & _mask32;
      x4 = _rotl(x4 ^ x8, 7);

      x1 = (x1 + x5) & _mask32;
      x13 = _rotl(x13 ^ x1, 16);
      x9 = (x9 + x13) & _mask32;
      x5 = _rotl(x5 ^ x9, 12);
      x1 = (x1 + x5) & _mask32;
      x13 = _rotl(x13 ^ x1, 8);
      x9 = (x9 + x13) & _mask32;
      x5 = _rotl(x5 ^ x9, 7);

      x2 = (x2 + x6) & _mask32;
      x14 = _rotl(x14 ^ x2, 16);
      x10 = (x10 + x14) & _mask32;
      x6 = _rotl(x6 ^ x10, 12);
      x2 = (x2 + x6) & _mask32;
      x14 = _rotl(x14 ^ x2, 8);
      x10 = (x10 + x14) & _mask32;
      x6 = _rotl(x6 ^ x10, 7);

      x3 = (x3 + x7) & _mask32;
      x15 = _rotl(x15 ^ x3, 16);
      x11 = (x11 + x15) & _mask32;
      x7 = _rotl(x7 ^ x11, 12);
      x3 = (x3 + x7) & _mask32;
      x15 = _rotl(x15 ^ x3, 8);
      x11 = (x11 + x15) & _mask32;
      x7 = _rotl(x7 ^ x11, 7);

      x0 = (x0 + x5) & _mask32;
      x15 = _rotl(x15 ^ x0, 16);
      x10 = (x10 + x15) & _mask32;
      x5 = _rotl(x5 ^ x10, 12);
      x0 = (x0 + x5) & _mask32;
      x15 = _rotl(x15 ^ x0, 8);
      x10 = (x10 + x15) & _mask32;
      x5 = _rotl(x5 ^ x10, 7);

      x1 = (x1 + x6) & _mask32;
      x12 = _rotl(x12 ^ x1, 16);
      x11 = (x11 + x12) & _mask32;
      x6 = _rotl(x6 ^ x11, 12);
      x1 = (x1 + x6) & _mask32;
      x12 = _rotl(x12 ^ x1, 8);
      x11 = (x11 + x12) & _mask32;
      x6 = _rotl(x6 ^ x11, 7);

      x2 = (x2 + x7) & _mask32;
      x13 = _rotl(x13 ^ x2, 16);
      x8 = (x8 + x13) & _mask32;
      x7 = _rotl(x7 ^ x8, 12);
      x2 = (x2 + x7) & _mask32;
      x13 = _rotl(x13 ^ x2, 8);
      x8 = (x8 + x13) & _mask32;
      x7 = _rotl(x7 ^ x8, 7);

      x3 = (x3 + x4) & _mask32;
      x14 = _rotl(x14 ^ x3, 16);
      x9 = (x9 + x14) & _mask32;
      x4 = _rotl(x4 ^ x9, 12);
      x3 = (x3 + x4) & _mask32;
      x14 = _rotl(x14 ^ x3, 8);
      x9 = (x9 + x14) & _mask32;
      x4 = _rotl(x4 ^ x9, 7);
    }

    output
      ..[0] = x0 + input[0]
      ..[1] = x1 + input[1]
      ..[2] = x2 + input[2]
      ..[3] = x3 + input[3]
      ..[4] = x4 + input[4]
      ..[5] = x5 + input[5]
      ..[6] = x6 + input[6]
      ..[7] = x7 + input[7]
      ..[8] = x8 + input[8]
      ..[9] = x9 + input[9]
      ..[10] = x10 + input[10]
      ..[11] = x11 + input[11]
      ..[12] = x12 + input[12]
      ..[13] = x13 + input[13]
      ..[14] = x14 + input[14]
      ..[15] = x15 + input[15];
  }

  /// Poly1305 over `ad || pad16 || ciphertext || pad16 || len(ad) ||
  /// len(ciphertext)`, as RFC 8439 section 2.8 builds it.
  static Uint8List _tag(
    Uint32List key,
    Uint8List associatedData,
    Uint8List ciphertext,
    int length,
  ) {
    final poly = _Poly1305(key)
      ..update(associatedData, associatedData.length)
      ..update(ciphertext, length);
    final lengths = ByteData(16)
      ..setUint64(0, associatedData.length, Endian.little)
      ..setUint64(8, length, Endian.little);
    poly.update(Uint8List.view(lengths.buffer), 16);
    return poly.finish();
  }
}

/// Poly1305 in the 32-bit "donna" style: five 26-bit limbs. Each call to
/// [update] takes a whole message part. When [update] is `padded`, its tail
/// is filled with zeros to a full 16-byte block, which is what the AEAD
/// construction asks for; otherwise the tail is a short block, ended with
/// a 1 byte as plain Poly1305 does.
class _Poly1305 {
  _Poly1305(Uint32List key)
    : _r0 = key[0] & 0x3ffffff,
      _r1 = ((key[0] >> 26) | (key[1] << 6)) & 0x3ffff03,
      _r2 = ((key[1] >> 20) | (key[2] << 12)) & 0x3ffc0ff,
      _r3 = ((key[2] >> 14) | (key[3] << 18)) & 0x3f03fff,
      _r4 = (key[3] >> 8) & 0x00fffff,
      _pad = [key[4], key[5], key[6], key[7]];

  final int _r0;
  final int _r1;
  final int _r2;
  final int _r3;
  final int _r4;
  final List<int> _pad;
  int _h0 = 0;
  int _h1 = 0;
  int _h2 = 0;
  int _h3 = 0;
  int _h4 = 0;

  static const _mask = ChaChaPoly._mask26;
  static const _hibit = 1 << 24;

  void update(Uint8List data, int length, {bool padded = true}) {
    final whole = length & ~15;
    if (whole > 0) {
      _blocks(ByteData.sublistView(data, 0, whole), whole, _hibit);
    }

    if (whole == length) {
      return;
    }

    final tail = length - whole;
    final last = Uint8List(16)..setRange(0, tail, data, whole);
    if (padded) {
      _blocks(ByteData.sublistView(last), 16, _hibit);
      return;
    }

    last[tail] = 1;
    _blocks(ByteData.sublistView(last), 16, 0);
  }

  void _blocks(ByteData data, int length, int hibit) {
    final r0 = _r0;
    final r1 = _r1;
    final r2 = _r2;
    final r3 = _r3;
    final r4 = _r4;
    final s1 = r1 * 5;
    final s2 = r2 * 5;
    final s3 = r3 * 5;
    final s4 = r4 * 5;
    var h0 = _h0;
    var h1 = _h1;
    var h2 = _h2;
    var h3 = _h3;
    var h4 = _h4;

    for (var at = 0; at < length; at += 16) {
      final t0 = data.getUint32(at, Endian.little);
      final t1 = data.getUint32(at + 4, Endian.little);
      final t2 = data.getUint32(at + 8, Endian.little);
      final t3 = data.getUint32(at + 12, Endian.little);
      h0 += t0 & _mask;
      h1 += ((t0 >> 26) | (t1 << 6)) & _mask;
      h2 += ((t1 >> 20) | (t2 << 12)) & _mask;
      h3 += ((t2 >> 14) | (t3 << 18)) & _mask;
      h4 += (t3 >> 8) | hibit;

      final d0 = h0 * r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1;
      var d1 = h0 * r1 + h1 * r0 + h2 * s4 + h3 * s3 + h4 * s2;
      var d2 = h0 * r2 + h1 * r1 + h2 * r0 + h3 * s4 + h4 * s3;
      var d3 = h0 * r3 + h1 * r2 + h2 * r1 + h3 * r0 + h4 * s4;
      var d4 = h0 * r4 + h1 * r3 + h2 * r2 + h3 * r1 + h4 * r0;

      var carry = d0 >> 26;
      h0 = d0 & _mask;
      d1 += carry;
      carry = d1 >> 26;
      h1 = d1 & _mask;
      d2 += carry;
      carry = d2 >> 26;
      h2 = d2 & _mask;
      d3 += carry;
      carry = d3 >> 26;
      h3 = d3 & _mask;
      d4 += carry;
      carry = d4 >> 26;
      h4 = d4 & _mask;
      h0 += carry * 5;
      carry = h0 >> 26;
      h0 &= _mask;
      h1 += carry;
    }

    _h0 = h0;
    _h1 = h1;
    _h2 = h2;
    _h3 = h3;
    _h4 = h4;
  }

  Uint8List finish() {
    var h0 = _h0;
    var h1 = _h1;
    var h2 = _h2;
    var h3 = _h3;
    var h4 = _h4;

    var carry = h1 >> 26;
    h1 &= _mask;
    h2 += carry;
    carry = h2 >> 26;
    h2 &= _mask;
    h3 += carry;
    carry = h3 >> 26;
    h3 &= _mask;
    h4 += carry;
    carry = h4 >> 26;
    h4 &= _mask;
    h0 += carry * 5;
    carry = h0 >> 26;
    h0 &= _mask;
    h1 += carry;

    // h - p, kept when h >= p; picked without a branch.
    var g0 = h0 + 5;
    carry = g0 >> 26;
    g0 &= _mask;
    var g1 = h1 + carry;
    carry = g1 >> 26;
    g1 &= _mask;
    var g2 = h2 + carry;
    carry = g2 >> 26;
    g2 &= _mask;
    var g3 = h3 + carry;
    carry = g3 >> 26;
    g3 &= _mask;
    final g4 = h4 + carry - (1 << 26);

    final keepH = g4 >> 63;
    final keepG = ~keepH;
    h0 = (h0 & keepH) | (g0 & keepG);
    h1 = (h1 & keepH) | (g1 & keepG);
    h2 = (h2 & keepH) | (g2 & keepG);
    h3 = (h3 & keepH) | (g3 & keepG);
    h4 = (h4 & keepH) | (g4 & keepG);

    final w0 = (h0 | (h1 << 26)) & ChaChaPoly._mask32;
    final w1 = ((h1 >> 6) | (h2 << 20)) & ChaChaPoly._mask32;
    final w2 = ((h2 >> 12) | (h3 << 14)) & ChaChaPoly._mask32;
    final w3 = ((h3 >> 18) | (h4 << 8)) & ChaChaPoly._mask32;

    final out = ByteData(16);
    var sum = w0 + _pad[0];
    out.setUint32(0, sum & ChaChaPoly._mask32, Endian.little);
    sum = w1 + _pad[1] + (sum >> 32);
    out.setUint32(4, sum & ChaChaPoly._mask32, Endian.little);
    sum = w2 + _pad[2] + (sum >> 32);
    out.setUint32(8, sum & ChaChaPoly._mask32, Endian.little);
    sum = w3 + _pad[3] + (sum >> 32);
    out.setUint32(12, sum & ChaChaPoly._mask32, Endian.little);
    return Uint8List.view(out.buffer);
  }
}
