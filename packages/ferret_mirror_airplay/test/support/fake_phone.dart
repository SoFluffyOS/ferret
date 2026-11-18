import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:ferret_mirror_airplay/ferret_mirror_airplay.dart';

class PhoneResponse {
  const PhoneResponse(this.status, this.headers, this.body);

  final int status;
  final Map<String, String> headers;
  final Uint8List body;

  Map<String, Object?> get plist => BinaryPlistDecoder.decodeDict(body);
}

/// Plays the iPhone's side of a mirroring session against a receiver on
/// this machine: the same requests in the same order, with its own keys.
class FakePhone {
  FakePhone._(this._socket) {
    _socket.listen(
      (chunk) {
        _received.add(chunk);
        _wake();
      },
      onDone: () {
        closed = true;
        _wake();
      },
      onError: (Object _) {
        closed = true;
        _wake();
      },
    );
  }

  static Future<FakePhone> connect(int port) async =>
      FakePhone._(await Socket.connect(InternetAddress.loopbackIPv4, port));

  final Socket _socket;
  final BytesBuilder _received = BytesBuilder();
  final Random _random = Random(7);
  Completer<void>? _waiting;
  int _sequence = 0;
  bool closed = false;

  Uint8List? receiverSigningKey;
  Uint8List? sharedSecret;
  Uint8List? sessionKey;
  Socket? video;
  AesCtrStream? _videoCipher;

  Future<PhoneResponse> send(
    String method,
    String uri, {
    List<int> body = const [],
    String? contentType,
    String protocol = 'RTSP/1.0',
  }) async {
    final head = StringBuffer('$method $uri $protocol\r\n')
      ..write('CSeq: ${_sequence++}\r\n')
      ..write('User-Agent: AirPlay/745.83\r\n');
    if (contentType != null) {
      head.write('Content-Type: $contentType\r\n');
    }

    head.write('Content-Length: ${body.length}\r\n\r\n');
    _socket.add([...latin1.encode('$head'), ...body]);
    return _readResponse();
  }

  Future<PhoneResponse> sendPlist(
    String method,
    String uri,
    Map<String, Object?> dict,
  ) => send(
    method,
    uri,
    body: BinaryPlistEncoder.encode(dict),
    contentType: 'application/x-apple-binary-plist',
  );

  /// Pair-setup and both pair-verify steps, checking the receiver's
  /// signature on the way. Returns the status of the last step.
  Future<int> pair({bool breakSignature = false}) async {
    final setup = await send('POST', '/pair-setup', body: _bytes(32));
    receiverSigningKey = setup.body;

    final x25519 = X25519();
    final ed25519 = Ed25519();
    final ephemeral = await x25519.newKeyPair();
    final signing = await ed25519.newKeyPair();
    final ourPublic = (await ephemeral.extractPublicKey()).bytes;
    final ourSigningKey = (await signing.extractPublicKey()).bytes;
    final first = await send(
      'POST',
      '/pair-verify',
      body: [1, 0, 0, 0, ...ourPublic, ...ourSigningKey],
    );
    final theirPublic = first.body.sublist(0, 32);
    final secret = await x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(theirPublic, type: KeyPairType.x25519),
    );
    final shared = Uint8List.fromList(await secret.extractBytes());
    sharedSecret = shared;

    final cipher = AesCtrStream(
      _hash16('Pair-Verify-AES-Key', shared),
      _hash16('Pair-Verify-AES-IV', shared),
    );
    final theirSignature = cipher.process(first.body.sublist(32));
    final genuine = await ed25519.verify(
      [...theirPublic, ...ourPublic],
      signature: Signature(
        theirSignature,
        publicKey: SimplePublicKey(setup.body, type: KeyPairType.ed25519),
      ),
    );
    if (!genuine) {
      throw StateError('The receiver signed with another key');
    }

    final signature = await ed25519.sign([
      ...ourPublic,
      ...theirPublic,
    ], keyPair: signing);
    final encrypted = cipher.process(Uint8List.fromList(signature.bytes));
    if (breakSignature) {
      encrypted[0] ^= 1;
    }

    final second = await send(
      'POST',
      '/pair-verify',
      body: [0, 0, 0, 0, ...encrypted],
    );
    return second.status;
  }

  /// Both FairPlay requests, then the first SETUP with the encrypted key.
  /// The key is found by running the same playfair code a phone's
  /// counterpart would.
  Future<PhoneResponse> setupSession({String name = 'Test iPhone'}) async {
    final setupRequest = Uint8List(16)
      ..setRange(0, 4, 'FPLY'.codeUnits)
      ..[4] = 3
      ..[5] = 1
      ..[6] = 1
      ..[14] = 2;
    await send('POST', '/fp-setup', body: setupRequest);
    final keyMessage = _bytes(164)
      ..setRange(0, 4, 'FPLY'.codeUnits)
      ..[4] = 3
      ..[12] = 2;
    await send('POST', '/fp-setup', body: keyMessage);

    final encryptedKey = _bytes(72);
    sessionKey = MirrorStreamKeys.sessionKey(
      playfairDecrypt(keyMessage, encryptedKey),
      sharedSecret,
    );
    return sendPlist('SETUP', 'rtsp://127.0.0.1/1234', {
      'deviceID': 'AA:BB:CC:DD:EE:FF',
      'name': name,
      'model': 'iPhone14,2',
      'ekey': encryptedKey,
      'eiv': _bytes(16),
      'timingProtocol': 'NTP',
      'timingPort': 0,
    });
  }

  /// The second SETUP, asking for the mirroring stream, then connects to
  /// the port the receiver answered with.
  Future<PhoneResponse> setupVideo({
    int streamConnectionId = -1234567890123456789,
    bool withAudio = false,
  }) async {
    final response = await sendPlist('SETUP', 'rtsp://127.0.0.1/1234', {
      'streams': [
        {'type': 110, 'streamConnectionID': streamConnectionId},
        if (withAudio) {'type': 96, 'ct': 8, 'controlPort': 50000},
      ],
    });
    if (response.status != 200) {
      return response;
    }

    final streams = response.plist['streams'];
    if (streams case [{'dataPort': final int dataPort}, ...]) {
      final key = sessionKey ?? Uint8List(16);
      final keys = MirrorStreamKeys.forStream(key, streamConnectionId);
      _videoCipher = AesCtrStream(keys.key, keys.iv);
      video = await Socket.connect(InternetAddress.loopbackIPv4, dataPort);
    }

    return response;
  }

  void sendVideo(Uint8List packet) => video?.add(packet);

  /// [payload] as the video stream's cipher encrypts it.
  Uint8List encrypt(Uint8List payload) =>
      _videoCipher?.process(payload) ?? payload;

  Future<void> close() async {
    video?.destroy();
    _socket.destroy();
  }

  /// Completes when the receiver closed the control connection.
  Future<void> waitClosed() async {
    while (!closed) {
      await _nextBytes();
    }
  }

  Future<PhoneResponse> _readResponse() async {
    while (true) {
      final bytes = _received.toBytes();
      final headEnd = _indexOf(bytes, const [13, 10, 13, 10]);
      if (headEnd >= 0) {
        final lines = latin1.decode(bytes.sublist(0, headEnd)).split('\r\n');
        final headers = {
          for (final line in lines.skip(1))
            line.split(': ').first.toLowerCase(): line.split(': ').last,
        };
        final length = int.parse(headers['content-length'] ?? '0');
        final bodyStart = headEnd + 4;
        if (bytes.length >= bodyStart + length) {
          _received
            ..clear()
            ..add(bytes.sublist(bodyStart + length));
          return PhoneResponse(
            int.parse(lines.first.split(' ')[1]),
            headers,
            bytes.sublist(bodyStart, bodyStart + length),
          );
        }
      }

      if (closed) {
        throw StateError('The receiver closed the connection');
      }

      await _nextBytes();
    }
  }

  Future<void> _nextBytes() {
    final waiting = Completer<void>();
    _waiting = waiting;
    return waiting.future.timeout(const Duration(seconds: 5));
  }

  void _wake() {
    final waiting = _waiting;
    _waiting = null;
    waiting?.complete();
  }

  int _indexOf(Uint8List bytes, List<int> pattern) {
    for (var index = 0; index <= bytes.length - pattern.length; index++) {
      var found = true;
      for (var offset = 0; offset < pattern.length; offset++) {
        if (bytes[index + offset] != pattern[offset]) {
          found = false;
          break;
        }
      }

      if (found) {
        return index;
      }
    }

    return -1;
  }

  Uint8List _bytes(int length) => Uint8List.fromList(
    List.generate(length, (_) => _random.nextInt(256)),
  );

  Uint8List _hash16(String salt, Uint8List secret) => Uint8List.fromList(
    hashes.sha512
        .convert([...utf8.encode(salt), ...secret])
        .bytes
        .sublist(0, 16),
  );
}
