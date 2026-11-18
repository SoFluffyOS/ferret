import 'dart:typed_data';

import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hex.dart';

Uint8List _keyMessage() => Uint8List.fromList(
  List.generate(164, (index) => (index * 7 + 3) & 0xff),
)..[12] = 2;

Uint8List _encryptedKey() => Uint8List.fromList(
  List.generate(72, (index) => (index * 13 + 5) & 0xff),
);

Uint8List _setupRequest(int mode) => Uint8List(16)
  ..setRange(0, 4, 'FPLY'.codeUnits)
  ..[4] = 3
  ..[5] = 1
  ..[6] = 1
  ..[14] = mode;

Uint8List _handshakeRequest() => _keyMessage()
  ..setRange(0, 4, 'FPLY'.codeUnits)
  ..[4] = 3;

void main() {
  group('playfair (the vendored C code, through FFI)', () {
    test('gives the key the same C code gives when run on its own', () {
      expect(
        hex(playfairDecrypt(_keyMessage(), _encryptedKey())),
        '09a756931e8637e79e8257eeab4b5ea9',
      );
    });

    test('gives the known key for an all-zero message and key', () {
      expect(
        hex(playfairDecrypt(Uint8List(164), Uint8List(72))),
        '3ba470ef5781b366dbb21a1fa2135dbc',
      );
    });

    test('refuses a mode byte the C code would read out of bounds with', () {
      expect(
        () => playfairDecrypt(_keyMessage()..[12] = 4, _encryptedKey()),
        throwsArgumentError,
      );
      expect(
        () => playfairDecrypt(Uint8List(163), _encryptedKey()),
        throwsArgumentError,
      );
      expect(
        () => playfairDecrypt(_keyMessage(), Uint8List(71)),
        throwsArgumentError,
      );
    });

    test('leaves its inputs as they were', () {
      final keyMessage = _keyMessage();
      final encryptedKey = _encryptedKey();

      playfairDecrypt(keyMessage, encryptedKey);

      expect(keyMessage, _keyMessage());
      expect(encryptedKey, _encryptedKey());
    });
  });

  group('FairPlaySession', () {
    test('answers the first request with the fixed reply of its mode', () {
      for (var mode = 0; mode < 4; mode++) {
        final answer = FairPlaySession().answer(_setupRequest(mode));

        expect(answer, hasLength(142));
        expect(answer, FairPlayReplies.byMode[mode]);
        expect(answer?[13], mode);
      }
    });

    test(
      'answers the second request with the header and its last 20 bytes',
      () {
        final request = _handshakeRequest();

        final answer = FairPlaySession().answer(request);

        expect(answer, [
          ...FairPlayReplies.handshakeHeader,
          ...request.sublist(144),
        ]);
      },
    );

    test('decrypts the key with the message of the second request', () {
      Uint8List? seenMessage;
      final session = FairPlaySession(
        decrypt: (keyMessage, encryptedKey) {
          seenMessage = keyMessage;
          return Uint8List.fromList(encryptedKey.sublist(0, 16));
        },
      );
      final request = _handshakeRequest();
      session.answer(request);

      final key = session.decryptKey(_encryptedKey());

      expect(seenMessage, request);
      expect(key, _encryptedKey().sublist(0, 16));
    });

    test('has no key before the second request', () {
      final session = FairPlaySession()..answer(_setupRequest(0));

      expect(session.decryptKey(_encryptedKey()), isNull);
    });

    test('refuses other versions, modes and sizes', () {
      final session = FairPlaySession();

      expect(session.answer(_setupRequest(0)..[4] = 2), isNull);
      expect(session.answer(_setupRequest(4)), isNull);
      expect(session.answer(_handshakeRequest()..[4] = 2), isNull);
      expect(session.answer(_handshakeRequest()..[12] = 4), isNull);
      expect(session.answer(Uint8List(20)), isNull);
      expect(session.decryptKey(Uint8List(16)), isNull);
    });

    test('a key of the wrong size is refused', () {
      final session = FairPlaySession()..answer(_handshakeRequest());

      expect(session.decryptKey(Uint8List(71)), isNull);
    });
  });
}
