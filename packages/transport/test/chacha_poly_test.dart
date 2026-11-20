import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:test/test.dart';
import 'package:transport/noise/chacha_poly.dart';

Uint8List _hex(String hex) => Uint8List.fromList([
  for (var index = 0; index < hex.length; index += 2)
    int.parse(hex.substring(index, index + 2), radix: 16),
]);

void main() {
  group('ChaChaPoly', () {
    test('matches the RFC 8439 section 2.8.2 test vector', () {
      final key = _hex(
        '808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f',
      );
      final nonce = _hex('070000004041424344454647');
      final aad = _hex('50515253c0c1c2c3c4c5c6c7');
      final plaintext = utf8.encode(
        "Ladies and Gentlemen of the class of '99: If I could offer you only "
        'one tip for the future, sunscreen would be it.',
      );
      final expected = _hex(
        'd31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d6'
        '3dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b36'
        '92ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc'
        '3ff4def08e4b7a9de576d26586cec64b6116'
        '1ae10b594f09e26a7e902ecbd0600691',
      );

      final sealed = ChaChaPoly.encrypt(key, nonce, aad, plaintext);

      expect(sealed, expected);
      expect(ChaChaPoly.decrypt(key, nonce, aad, sealed), plaintext);
    });

    test('gives the same bytes as the cryptography package', () async {
      final random = Random(21);
      const reference = DartChacha20.poly1305Aead();
      for (final length in [
        0,
        1,
        15,
        16,
        17,
        63,
        64,
        65,
        127,
        300,
        4096,
        65518,
      ]) {
        final key = List.generate(32, (_) => random.nextInt(256));
        final nonce = List.generate(12, (_) => random.nextInt(256));
        final aad = List.generate(length % 23, (_) => random.nextInt(256));
        final plaintext = Uint8List.fromList(
          List.generate(length, (_) => random.nextInt(256)),
        );

        final box = await reference.encrypt(
          plaintext,
          secretKey: SecretKey(key),
          nonce: nonce,
          aad: aad,
        );
        final sealed = ChaChaPoly.encrypt(key, nonce, aad, plaintext);

        expect(sealed, [
          ...box.cipherText,
          ...box.mac.bytes,
        ], reason: '$length');
        expect(
          ChaChaPoly.decrypt(key, nonce, aad, sealed),
          plaintext,
          reason: '$length',
        );
      }
    });

    test('refuses a changed ciphertext, tag or associated data', () {
      final key = List.filled(32, 7);
      final nonce = List.filled(12, 1);
      final sealed = ChaChaPoly.encrypt(key, nonce, [1, 2], [9, 8, 7, 6, 5]);

      for (var index = 0; index < sealed.length; index++) {
        final changed = Uint8List.fromList(sealed)..[index] ^= 1;
        expect(ChaChaPoly.decrypt(key, nonce, [1, 2], changed), isNull);
      }

      expect(ChaChaPoly.decrypt(key, nonce, [1, 3], sealed), isNull);
      expect(
        ChaChaPoly.decrypt(key, nonce, [1, 2], sealed.sublist(0, 15)),
        isNull,
      );
    });

    test('leaves the plaintext it was given alone', () {
      final plaintext = Uint8List.fromList(List.generate(100, (i) => i));
      final copy = Uint8List.fromList(plaintext);

      ChaChaPoly.encrypt(List.filled(32, 3), List.filled(12, 4), [], plaintext);

      expect(plaintext, copy);
    });
  });
}
