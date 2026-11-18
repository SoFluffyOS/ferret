import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:interop_quickshare/crypto/d2d_keys.dart';
import 'package:interop_quickshare/crypto/secure_bytes.dart';
import 'package:interop_quickshare/models/models.dart';
import 'package:interop_quickshare/proto/proto.dart';
import 'package:pointycastle/export.dart';

/// Wraps frames into encrypted, signed and numbered secure messages, and
/// unwraps the other side's.
///
/// Each direction counts its messages from 1. A message with any other
/// number than the next one is refused, which stops replays and
/// reordering.
class SecureMessageCodec {
  SecureMessageCodec(this.keys, {Random? random}) : _random = random;

  static const _deviceToDeviceMessage = 13;
  static const _metadataVersion = 1;
  static const _ivLength = 16;
  static final List<int> _publicMetadata = GcmMetadata(
    type: _deviceToDeviceMessage,
    version: _metadataVersion,
  ).writeToBuffer();

  final D2DKeys keys;
  final Random? _random;
  int _sent = 0;
  int _received = 0;

  /// Encrypts and signs [message], the bytes of one frame.
  Uint8List encode(List<int> message) {
    _sent++;
    final iv = SecureBytes.random(_ivLength, _random);
    final body =
        _cipher(
          encrypt: true,
          key: keys.encryptKey,
          iv: iv,
        ).process(
          DeviceToDeviceMessage(
            message: message,
            sequenceNumber: _sent,
          ).writeToBuffer(),
        );
    final headerAndBody = HeaderAndBody(
      header: Header(
        signatureScheme: .HMAC_SHA256,
        encryptionScheme: .AES_256_CBC,
        iv: iv,
        publicMetadata: _publicMetadata,
      ),
      body: body,
    ).writeToBuffer();

    return SecureMessage(
      headerAndBody: headerAndBody,
      signature: Hmac(sha256, keys.signKey).convert(headerAndBody).bytes,
    ).writeToBuffer();
  }

  /// Verifies and decrypts one secure message, and returns the frame
  /// inside. Throws a [QuickShareException] when anything about it is
  /// off; the connection must close then.
  Uint8List decode(List<int> secureMessage) {
    final SecureMessage message;
    final HeaderAndBody headerAndBody;
    try {
      message = SecureMessage.fromBuffer(secureMessage);
      headerAndBody = HeaderAndBody.fromBuffer(message.headerAndBody);
    } on Object {
      throw const QuickShareException(.tampered, 'Unreadable secure message');
    }

    final expected = Hmac(
      sha256,
      keys.verifyKey,
    ).convert(message.headerAndBody).bytes;
    if (!SecureBytes.same(expected, message.signature)) {
      throw const QuickShareException(.tampered, 'Signature');
    }

    final header = headerAndBody.header;
    if (header.signatureScheme != SigScheme.HMAC_SHA256 ||
        header.encryptionScheme != EncScheme.AES_256_CBC ||
        header.iv.length != _ivLength) {
      throw const QuickShareException(.tampered, 'Scheme');
    }

    final DeviceToDeviceMessage inner;
    try {
      inner = DeviceToDeviceMessage.fromBuffer(
        _cipher(
          encrypt: false,
          key: keys.decryptKey,
          iv: Uint8List.fromList(header.iv),
        ).process(Uint8List.fromList(headerAndBody.body)),
      );
    } on Object {
      throw const QuickShareException(.tampered, 'Body');
    }

    if (inner.sequenceNumber != _received + 1) {
      throw const QuickShareException(.tampered, 'Sequence');
    }

    _received++;
    return Uint8List.fromList(inner.message);
  }

  PaddedBlockCipher _cipher({
    required bool encrypt,
    required Uint8List key,
    required Uint8List iv,
  }) =>
      PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()))..init(
        encrypt,
        PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ParametersWithIV(KeyParameter(key), iv),
          null,
        ),
      );
}
