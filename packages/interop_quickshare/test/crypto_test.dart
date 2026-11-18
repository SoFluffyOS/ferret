import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:interop_quickshare/interop_quickshare.dart';
import 'package:test/test.dart';

import 'support/loopback.dart';

void main() {
  group('Hkdf', () {
    test('matches RFC 5869 test case 1', () {
      final output = Hkdf.derive(
        key: hex('0b' * 22),
        salt: hex('000102030405060708090a0b0c'),
        info: hex('f0f1f2f3f4f5f6f7f8f9'),
        length: 42,
      );

      expect(
        toHex(output),
        '3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf'
        '34007208d5b887185865',
      );
    });
  });

  group('P-256', () {
    // RFC 5903 section 8.1.
    final initiator = BigInt.parse(
      'c88f01f510d9ac3f70a292daa2316de544e9aab8afe84049c62a9c57862d1433',
      radix: 16,
    );
    final responder = BigInt.parse(
      'c6ef9c5d78ae012a011164acb397ce2088685d8f06bf9be0b283ab46476bee53',
      radix: 16,
    );

    test('derives the public key and shared secret of RFC 5903', () {
      final first = P256KeyPair.fromSecret(initiator);
      final second = P256KeyPair.fromSecret(responder);

      expect(
        first?.publicKey.x.toRadixString(16),
        'dad0b65394221cf9b051e1feca5787d098dfe637fc90b9ef945d0c3772581180',
      );
      expect(
        second?.publicKey.y.toRadixString(16),
        '56fbf3ca366cc23e8157854c13c58d6aac23f046ada30f8353e74f33039872ab',
      );
      final shared = first?.agree(second?.publicKey ?? first.publicKey);
      expect(
        toHex(shared ?? const []),
        'd6840f6b42f6edafd13116e0e12565202fef8e9ece7dce03812464d04b9442de',
      );
      expect(second?.agree(first?.publicKey ?? second.publicKey), shared);
    });

    test('encodes coordinates like phones do, sign byte included', () {
      final key = P256KeyPair.fromSecret(initiator)?.publicKey;
      final encoded = GenericPublicKey.fromBuffer(key?.encode() ?? const []);

      // Both coordinates of this key start with a set top bit.
      expect(encoded.type, PublicKeyType.EC_P256);
      expect(encoded.ecP256PublicKey.x, hasLength(33));
      expect(encoded.ecP256PublicKey.x.first, 0);
      expect(encoded.ecP256PublicKey.y, hasLength(32));
    });

    test('reads keys with and without the sign byte', () {
      final key = P256KeyPair.generate(Random(1)).publicKey;
      final bare = GenericPublicKey(
        type: .EC_P256,
        ecP256PublicKey: EcP256PublicKey(
          x: _unsigned(key.x),
          y: _unsigned(key.y),
        ),
      ).writeToBuffer();

      expect(P256PublicKey.decode(key.encode())?.x, key.x);
      expect(P256PublicKey.decode(bare)?.y, key.y);
    });

    test('refuses points that are not on the curve', () {
      final key = P256KeyPair.generate(Random(2)).publicKey;
      final offCurve = P256PublicKey(key.x, key.y + BigInt.one);

      expect(P256PublicKey.decode(offCurve.encode()), isNull);
      expect(P256PublicKey.decode(utf8.encode('not a key')), isNull);
      expect(
        P256PublicKey.decode(
          GenericPublicKey(type: .RSA2048).writeToBuffer(),
        ),
        isNull,
      );
    });
  });

  group('key derivation', () {
    // Computed with an independent implementation of the published
    // steps, from the RFC 5903 shared secret and these transcripts.
    final keys = Ukey2Keys.derive(
      sharedSecret: hex(
        'd6840f6b42f6edafd13116e0e12565202fef8e9ece7dce03812464d04b9442de',
      ),
      clientInit: [for (var byte = 0; byte < 40; byte++) byte],
      serverInit: [for (var byte = 100; byte < 160; byte++) byte],
    );

    test('derives the authentication string and next secret', () {
      expect(
        toHex(keys.authString),
        '5aa2336f336df8fcf5e1e86feafb292c0683a427979d1edc7efa12c74feb7edd',
      );
      expect(
        toHex(keys.nextSecret),
        'add44d254a102990f29ddfb903d5b74b6c381f796980440db3f628eb1b8560e4',
      );
    });

    test('derives the frame keys for both roles', () {
      final server = D2DKeys.derive(keys.nextSecret, isServer: true);
      final client = D2DKeys.derive(keys.nextSecret, isServer: false);

      expect(
        toHex(client.encryptKey),
        'a75f4812d79b572d51e4f9052568e3178060a5c7817b0e20f1642a04040c3023',
      );
      expect(
        toHex(client.signKey),
        '4a6aaf38006ab74a044ace97ef4af2fd21755f1871941bb2e3f3de778470228a',
      );
      expect(
        toHex(server.encryptKey),
        '8a936a2974fe3d4518694d229dc94326f34105686d36f81353985f5b4c4bdd67',
      );
      expect(
        toHex(server.signKey),
        '0ed0737fad59d758d18251505efa306c83f4398707563dbacb33235ce751476c',
      );
      expect(server.decryptKey, client.encryptKey);
      expect(server.verifyKey, client.signKey);
      expect(client.decryptKey, server.encryptKey);
      expect(client.verifyKey, server.signKey);
    });

    test('turns the authentication string into the PIN', () {
      expect(QuickSharePin.of(keys.authString), '1492');
    });
  });

  group('QuickSharePin', () {
    test('pads to four digits', () {
      expect(QuickSharePin.of(List.filled(32, 0)), '0000');
      expect(QuickSharePin.of([1]), '0001');
      expect(QuickSharePin.of([0, 1]), '0031');
    });

    test('treats bytes as signed, like phones do', () {
      expect(QuickSharePin.of([0xff]), '0001');
      expect(QuickSharePin.of([0x80, 0x80]), '4096');
      expect(QuickSharePin.of(List.filled(32, 0xff)), '6509');
      expect(
        QuickSharePin.of([for (var byte = 0; byte < 32; byte++) byte]),
        '5095',
      );
    });
  });

  group('UKEY2', () {
    test('client and server arrive at the same keys', () {
      final client = Ukey2Client();
      final server = Ukey2Server();

      final serverInit = server.serverInit(client.clientInit());
      final (:clientFinish, :keys) = client.finish(serverInit);
      final serverKeys = server.finish(clientFinish);

      expect(serverKeys.authString, keys.authString);
      expect(serverKeys.nextSecret, keys.nextSecret);
      expect(serverKeys.authString, hasLength(32));
      expect(
        QuickSharePin.of(serverKeys.authString),
        QuickSharePin.of(keys.authString),
      );
    });

    test('two handshakes never share keys', () {
      Ukey2Keys run() {
        final client = Ukey2Client();
        final server = Ukey2Server();
        final serverInit = server.serverInit(client.clientInit());
        return server.finish(client.finish(serverInit).clientFinish);
      }

      expect(run().nextSecret, isNot(run().nextSecret));
    });

    test('the init frames carry what the protocol asks for', () {
      final client = Ukey2Client();
      final message = Ukey2Message.fromBuffer(client.clientInit());
      final init = Ukey2ClientInit.fromBuffer(message.messageData);

      expect(message.messageType, Ukey2Message_Type.CLIENT_INIT);
      expect(init.version, 1);
      expect(init.random, hasLength(32));
      expect(init.nextProtocol, 'AES_256_CBC-HMAC_SHA256');
      expect(
        init.cipherCommitments.single.handshakeCipher,
        Ukey2HandshakeCipher.P256_SHA512,
      );
      expect(init.cipherCommitments.single.commitment, hasLength(64));

      final serverInit = Ukey2ServerInit.fromBuffer(
        Ukey2Message.fromBuffer(
          Ukey2Server().serverInit(client.clientInit()),
        ).messageData,
      );
      expect(serverInit.version, 1);
      expect(serverInit.random, hasLength(32));
      expect(serverInit.handshakeCipher, Ukey2HandshakeCipher.P256_SHA512);
      expect(P256PublicKey.decode(serverInit.publicKey), isNotNull);
    });

    test('refuses a finish that differs from the commitment', () {
      final client = Ukey2Client();
      final server = Ukey2Server()..serverInit(client.clientInit());
      final other = Ukey2Client()..clientInit();
      final swapped = other
          .finish(Ukey2Server().serverInit(other.clientInit()))
          .clientFinish;

      expect(
        () => server.finish(swapped),
        throwsA(
          isA<Ukey2Exception>().having((e) => e.alert, 'alert', isNull),
        ),
      );
    });

    test('answers unknown versions, ciphers and protocols with alerts', () {
      Uint8List initWith({
        int version = 1,
        int randomLength = 32,
        Ukey2HandshakeCipher cipher = .P256_SHA512,
        String nextProtocol = 'AES_256_CBC-HMAC_SHA256',
      }) => Ukey2Message(
        messageType: .CLIENT_INIT,
        messageData: Ukey2ClientInit(
          version: version,
          random: List.filled(randomLength, 1),
          cipherCommitments: [
            Ukey2ClientInit_CipherCommitment(
              handshakeCipher: cipher,
              commitment: List.filled(64, 2),
            ),
          ],
          nextProtocol: nextProtocol,
        ).writeToBuffer(),
      ).writeToBuffer();

      Ukey2Alert_AlertType? alertFor(Uint8List frame) {
        try {
          Ukey2Server().serverInit(frame);
        } on Ukey2Exception catch (error) {
          final sent = Ukey2Message.fromBuffer(error.alertFrame ?? const []);
          expect(sent.messageType, Ukey2Message_Type.ALERT);
          return Ukey2Alert.fromBuffer(sent.messageData).type;
        }

        return null;
      }

      expect(alertFor(initWith()), isNull);
      expect(alertFor(initWith(version: 2)), Ukey2Alert_AlertType.BAD_VERSION);
      expect(
        alertFor(initWith(randomLength: 8)),
        Ukey2Alert_AlertType.BAD_RANDOM,
      );
      expect(
        alertFor(initWith(cipher: .CURVE25519_SHA512)),
        Ukey2Alert_AlertType.BAD_HANDSHAKE_CIPHER,
      );
      expect(
        alertFor(initWith(nextProtocol: 'ROT13')),
        Ukey2Alert_AlertType.BAD_NEXT_PROTOCOL,
      );
      expect(
        alertFor(
          Ukey2Message(messageType: .SERVER_INIT).writeToBuffer(),
        ),
        Ukey2Alert_AlertType.BAD_MESSAGE_TYPE,
      );
    });

    test('the client refuses a server key off the curve', () {
      final client = Ukey2Client()..clientInit();
      final key = P256KeyPair.generate().publicKey;
      final badInit = Ukey2Message(
        messageType: .SERVER_INIT,
        messageData: Ukey2ServerInit(
          version: 1,
          random: List.filled(32, 3),
          handshakeCipher: .P256_SHA512,
          publicKey: P256PublicKey(key.x, key.y + BigInt.one).encode(),
        ).writeToBuffer(),
      ).writeToBuffer();

      expect(
        () => client.finish(badInit),
        throwsA(
          isA<Ukey2Exception>().having(
            (e) => e.alert,
            'alert',
            Ukey2Alert_AlertType.BAD_PUBLIC_KEY,
          ),
        ),
      );
    });
  });

  group('SecureMessageCodec', () {
    final secret = List.generate(32, (index) => index);

    (SecureMessageCodec, SecureMessageCodec) pair() => (
      SecureMessageCodec(D2DKeys.derive(secret, isServer: false)),
      SecureMessageCodec(D2DKeys.derive(secret, isServer: true)),
    );

    test('round-trips frames in both directions', () {
      final (client, server) = pair();
      final big = randomBytes(100 * 1024);

      expect(
        server.decode(client.encode(utf8.encode('one'))),
        utf8.encode('one'),
      );
      expect(server.decode(client.encode(big)), big);
      expect(client.decode(server.encode(const [])), isEmpty);
    });

    test('writes the header phones expect', () {
      final (client, _) = pair();
      final message = SecureMessage.fromBuffer(client.encode([1, 2, 3]));
      final header = HeaderAndBody.fromBuffer(message.headerAndBody).header;
      final metadata = GcmMetadata.fromBuffer(header.publicMetadata);

      expect(message.signature, hasLength(32));
      expect(header.signatureScheme, SigScheme.HMAC_SHA256);
      expect(header.encryptionScheme, EncScheme.AES_256_CBC);
      expect(header.iv, hasLength(16));
      expect(metadata.type, 13);
      expect(metadata.version, 1);
    });

    test('never reuses an IV', () {
      final (client, _) = pair();
      List<int> ivOf(Uint8List frame) => HeaderAndBody.fromBuffer(
        SecureMessage.fromBuffer(frame).headerAndBody,
      ).header.iv;

      expect(ivOf(client.encode([1])), isNot(ivOf(client.encode([1]))));
    });

    test('refuses a changed frame', () {
      final (client, server) = pair();
      final frame = client.encode(utf8.encode('payload'));
      frame[frame.length ~/ 2] ^= 0x01;

      expect(() => server.decode(frame), _throwsTampered);
    });

    test('refuses a replayed or skipped frame', () {
      final (client, server) = pair();
      final first = client.encode([1]);
      final second = client.encode([2]);
      final third = client.encode([3]);

      expect(server.decode(first), [1]);
      expect(() => server.decode(first), _throwsTampered);
      expect(() => server.decode(third), _throwsTampered);
      expect(server.decode(second), [2]);
    });

    test('refuses frames made with the keys of the other direction', () {
      final (client, _) = pair();
      final otherClient = SecureMessageCodec(
        D2DKeys.derive(secret, isServer: false),
      );

      expect(() => otherClient.decode(client.encode([1])), _throwsTampered);
    });
  });

  group('DecodeWorker', () {
    final secret = List.generate(32, (index) => 255 - index);

    test('decodes on another isolate, in order', () async {
      final sender = SecureMessageCodec(
        D2DKeys.derive(secret, isServer: false),
      );
      final worker = await DecodeWorker.start(
        D2DKeys.derive(secret, isServer: true),
      );
      addTearDown(worker.stop);
      final big = randomBytes(600 * 1024);

      expect(await worker.decode(sender.encode([1, 2, 3])), [1, 2, 3]);
      expect(await worker.decode(sender.encode(big)), big);
    });

    test('refuses a changed or replayed frame', () async {
      final sender = SecureMessageCodec(
        D2DKeys.derive(secret, isServer: false),
      );
      final worker = await DecodeWorker.start(
        D2DKeys.derive(secret, isServer: true),
      );
      addTearDown(worker.stop);
      final first = sender.encode([1]);
      final changed = sender.encode([2]);
      changed[changed.length - 1] ^= 0x01;

      expect(await worker.decode(first), [1]);
      await expectLater(worker.decode(first), _throwsTampered);
      await expectLater(worker.decode(changed), _throwsTampered);
    });

    test('fails what is waiting when it is stopped', () async {
      final sender = SecureMessageCodec(
        D2DKeys.derive(secret, isServer: false),
      );
      final worker = await DecodeWorker.start(
        D2DKeys.derive(secret, isServer: true),
      );

      final waiting = worker.decode(sender.encode(randomBytes(900 * 1024)));
      worker.stop();

      await expectLater(waiting, throwsA(isA<QuickShareException>()));
      expect(
        () => worker.decode(sender.encode([1])),
        throwsA(isA<QuickShareException>()),
      );
    });
  });
}

final _throwsTampered = throwsA(
  isA<QuickShareException>().having(
    (error) => error.failure,
    'failure',
    QuickShareFailure.tampered,
  ),
);

List<int> _unsigned(BigInt value) {
  final bytes = Uint8List(32);
  var rest = value;
  for (var index = 31; index >= 0; index--) {
    bytes[index] = (rest & BigInt.from(0xff)).toInt();
    rest >>= 8;
  }

  return bytes;
}
