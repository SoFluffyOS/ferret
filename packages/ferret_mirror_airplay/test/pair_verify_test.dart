import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hex.dart';

// Keys from RFC 8032 (Ed25519 tests 1 and 2) and RFC 7748 (X25519, section
// 6.1). The encrypted signatures were computed apart from this code, with
// the OpenSSL command line following what UxPlay's pairing.c does.
final _receiverSeed = unhex(
  '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60',
);
const _receiverPublic =
    'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a';
final _phoneSigningKey = unhex(
  '3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c',
);
final _receiverEphemeral = unhex(
  '77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a',
);
const _receiverEphemeralPublic =
    '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a';
final _phoneEphemeralPublic = unhex(
  'de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f',
);
const _sharedSecret =
    '4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742';
const _receiverSignatureEncrypted =
    '3b58331a0ae907cd80af41a1ce7183927a62b0ce2dc2e1b89be414949589e59c'
    '8b23ba53544511419f88eb240157394e9a2271b3fa8b9b58bda1075838fc1835';
final _phoneSignatureEncrypted = unhex(
  'a8c31001a49e6d0dbae6d915ac26d1a95af4c75fb34f107dbfa39ce10d7da36f'
  '120d119016798632c0b53d71ce6b9c6b4f8f90bc8acf07d76cbebd0fe9ae2f2c',
);

PairVerify _session() =>
    PairVerify(signingSeed: _receiverSeed, ephemeralSeed: _receiverEphemeral);

void main() {
  test('the public key comes from the signing seed', () async {
    expect(hex(await PairVerify.publicKeyOf(_receiverSeed)), _receiverPublic);
  });

  test(
    'the first step answers with our key and the encrypted signature',
    () async {
      final session = _session();

      final answer = await session.start(
        _phoneEphemeralPublic,
        _phoneSigningKey,
      );

      expect(
        hex(answer),
        '$_receiverEphemeralPublic$_receiverSignatureEncrypted',
      );
      expect(hex(session.sharedSecret ?? const []), _sharedSecret);
      expect(session.isVerified, isFalse);
    },
  );

  test('the second step accepts the phone\'s signature', () async {
    final session = _session();
    await session.start(_phoneEphemeralPublic, _phoneSigningKey);

    expect(await session.finish(_phoneSignatureEncrypted), isTrue);
    expect(session.isVerified, isTrue);
  });

  test('a signature that was changed is refused', () async {
    final session = _session();
    await session.start(_phoneEphemeralPublic, _phoneSigningKey);
    final changed = unhex(hex(_phoneSignatureEncrypted))..[10] ^= 1;

    expect(await session.finish(changed), isFalse);
    expect(session.isVerified, isFalse);
  });

  test('a signature made by another key is refused', () async {
    final session = _session();
    await session.start(_phoneEphemeralPublic, unhex(_receiverPublic));

    expect(await session.finish(_phoneSignatureEncrypted), isFalse);
  });

  test('the second step alone is refused', () async {
    expect(await _session().finish(_phoneSignatureEncrypted), isFalse);
  });

  test('each session makes its own key when none is fixed', () async {
    final first = PairVerify(signingSeed: _receiverSeed);
    final second = PairVerify(signingSeed: _receiverSeed);

    final firstAnswer = await first.start(
      _phoneEphemeralPublic,
      _phoneSigningKey,
    );
    final secondAnswer = await second.start(
      _phoneEphemeralPublic,
      _phoneSigningKey,
    );

    expect(hex(firstAnswer), isNot(hex(secondAnswer)));
  });

  test('keys of the wrong size are refused', () {
    expect(
      () => _session().start(unhex('0102'), _phoneSigningKey),
      throwsArgumentError,
    );
  });
}
