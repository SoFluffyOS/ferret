import 'dart:typed_data';

import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hex.dart';

// Every expected value here was printed by a small C program built from
// UxPlay's own mirror_buffer.c and crypto.c (OpenSSL underneath), fed the
// same inputs. See "How the tests know" in the README.
final _fairPlayKey = unhex('52fc036697777b2ecfdea9681a14b799');
final _sharedSecret = Uint8List.fromList(
  List.generate(32, (index) => 0xa0 + index),
);
const _sessionKey = '016e2a58035cebc466653a6b5fe2ef6b';
const _sizes = [37, 16, 21, 100, 17, 33];

const _packetsSmallId = [
  'c6a32b79ddcc09eaf52be36ad69df32a8ca41132563c9fea800f1b5ef8801233b75a2317dd',
  '840c97e79d6a4039491dde84974e213e',
  '9c3de334e681794e013fb93ba91868fbd0d5d97795',
  'ec86596802150e69bc7fdec15a830308f0d379847c02d0ff0766c25f496b65ba27c4ec97636529e8c8f33103bb163cc154f9427e79db8045ee1bd3453f426d7f28badff3d5062d43abc05edeac2a3ffe3d09880f751f928eb1f817186d67352095113a86',
  '7d311e4940bec3451f347859aea3feef8c',
  '601c5e925127feef574fb820d2984361e83ee2a1ebe1a1f099da92a69998ab1b1b',
];

const _packetsUnsignedId = [
  '6ae4bf177cb7edd1e7ba025fa4612ee88a680e8f17ea8d19ab6acd44b27e1b49f8f94ddfba',
  '3be7e78a86e6820240d7a298f7aa1b8e',
  '3157bb92cae6d984dd709ca8f3492685a4c10fe58e',
  '3e98f7acceaaecd4bb832c57f70e9a1e70e7e786374786a8c66cfad38a185b2f2a6803351c718e3e4c32ecf0f8ac9223804e0037982439c9d42c61bf900ae608663c07f0203e83fd96c49e9b29508b17d6909c6cba8a4687f36b31907c11a57a5aaf2709',
  'd5a1ba1686a6efad0ebce7a2924996f335',
  '0526bd109cf47ff8af0e9a0b78704330e004e79b69f1760f475eb4299a3bb1c63c',
];

/// The clear payloads the C program used: one counter running across all
/// packets, cut at [_sizes].
List<Uint8List> _clearPackets() {
  var counter = 0;
  return [
    for (final size in _sizes)
      Uint8List.fromList(List.generate(size, (_) => counter++ & 0xff)),
  ];
}

void _expectStream(int streamConnectionId, List<String> encrypted) {
  final keys = MirrorStreamKeys.forStream(
    unhex(_sessionKey),
    streamConnectionId,
  );
  final cipher = AesCtrStream(keys.key, keys.iv);
  final clear = _clearPackets();

  for (var index = 0; index < encrypted.length; index++) {
    expect(
      cipher.process(unhex(encrypted[index])),
      clear[index],
      reason: 'packet $index',
    );
  }
}

void main() {
  test('the session key is the FairPlay key hashed with the shared secret', () {
    expect(
      hex(MirrorStreamKeys.sessionKey(_fairPlayKey, _sharedSecret)),
      _sessionKey,
    );
  });

  test('without a shared secret the FairPlay key is the session key', () {
    expect(MirrorStreamKeys.sessionKey(_fairPlayKey, null), _fairPlayKey);
  });

  test('packets of any size decrypt as one running stream', () {
    _expectStream(0x123456789abcdef, _packetsSmallId);
  });

  test('a stream id with its top bit set is hashed as an unsigned number', () {
    // 0xfedcba9876543210, which Dart holds as a negative int.
    _expectStream(-81985529216486896, _packetsUnsignedId);
  });

  test('another stream id gives another key', () {
    final keys = MirrorStreamKeys.forStream(unhex(_sessionKey), 1);
    final cipher = AesCtrStream(keys.key, keys.iv);

    expect(
      cipher.process(unhex(_packetsSmallId.first)),
      isNot(_clearPackets().first),
    );
  });
}
