import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// AES-128 in counter mode as one running key stream: each call carries on
/// where the last one stopped, whatever the sizes. Encrypting and
/// decrypting are the same operation.
class AesCtrStream {
  AesCtrStream(Uint8List key, Uint8List iv)
    : _cipher = CTRStreamCipher(AESEngine())
        ..init(true, ParametersWithIV(KeyParameter(key), iv));

  final CTRStreamCipher _cipher;

  Uint8List process(Uint8List input) {
    final output = Uint8List(input.length);
    _cipher.processBytes(input, 0, input.length, output, 0);
    return output;
  }
}
