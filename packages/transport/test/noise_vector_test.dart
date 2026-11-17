import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transport/noise/noise.dart';

/// The Noise_XX_25519_ChaChaPoly_SHA256 case from the cacophony test vectors
/// (github.com/haskell-cryptography/cacophony, vectors/cacophony.txt).
void main() {
  test('matches the cacophony XX vector byte for byte', () async {
    final vector = jsonDecode(
      File('test/fixtures/noise_xx_25519_chachapoly_sha256.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    Uint8List hex(String key) => _fromHex(vector[key] as String);

    final initiator = await NoiseXXHandshake.create(
      initiator: true,
      staticKeyPair: await NoiseCrypto.keyPairFromPrivateKey(
        hex('init_static'),
      ),
      ephemeralKeyPair: await NoiseCrypto.keyPairFromPrivateKey(
        hex('init_ephemeral'),
      ),
      prologue: hex('init_prologue'),
    );
    final responder = await NoiseXXHandshake.create(
      initiator: false,
      staticKeyPair: await NoiseCrypto.keyPairFromPrivateKey(
        hex('resp_static'),
      ),
      ephemeralKeyPair: await NoiseCrypto.keyPairFromPrivateKey(
        hex('resp_ephemeral'),
      ),
      prologue: hex('resp_prologue'),
    );

    final messages = (vector['messages'] as List).cast<Map<String, dynamic>>();
    for (final (index, message) in messages.take(3).indexed) {
      final payload = _fromHex(message['payload'] as String);
      final expected = _fromHex(message['ciphertext'] as String);
      final (writer, reader) = switch (index.isEven) {
        true => (initiator, responder),
        false => (responder, initiator),
      };

      final written = await writer.writeMessage(payload);
      expect(
        _toHex(written),
        _toHex(expected),
        reason: 'handshake message $index',
      );
      expect(await reader.readMessage(written), payload);
    }

    final initiatorResult = await initiator.finish();
    final responderResult = await responder.finish();
    expect(_toHex(initiatorResult.handshakeHash), vector['handshake_hash']);
    expect(_toHex(responderResult.handshakeHash), vector['handshake_hash']);

    for (final (index, message) in messages.indexed.skip(3)) {
      final payload = _fromHex(message['payload'] as String);
      final expected = _fromHex(message['ciphertext'] as String);
      final (sender, receiver) = switch (index.isEven) {
        true => (initiatorResult, responderResult),
        false => (responderResult, initiatorResult),
      };

      final written = await sender.send.encryptWithAd(const [], payload);
      expect(
        _toHex(written),
        _toHex(expected),
        reason: 'transport message $index',
      );
      expect(await receiver.receive.decryptWithAd(const [], written), payload);
    }
  });
}

Uint8List _fromHex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

String _toHex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
