import 'dart:ffi';
import 'dart:typed_data';

@Native<Void Function(Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>)>(
  symbol: 'ferret_playfair_decrypt',
  isLeaf: true,
)
external void _playfairDecrypt(
  Pointer<Uint8> message3,
  Pointer<Uint8> cipherText,
  Pointer<Uint8> keyOut,
);

/// The vendored playfair C code: turns the 72-byte key an iPhone sends into
/// the 16-byte AES key, using the 164-byte FairPlay message that came before.
///
/// The C code trusts its input: byte 12 of the message picks one of four
/// tables, and a larger value reads past them. Both sizes and that byte
/// are checked here, since the message comes from the network.
Uint8List playfairDecrypt(Uint8List message3, Uint8List cipherText) {
  if (message3.length != playfairMessageLength ||
      cipherText.length != playfairKeyLength ||
      message3[playfairModeOffset] >= playfairModes) {
    throw ArgumentError('Not a FairPlay message and key');
  }

  final keyOut = Uint8List(16);
  _playfairDecrypt(message3.address, cipherText.address, keyOut.address);
  return keyOut;
}

const playfairMessageLength = 164;
const playfairKeyLength = 72;
const playfairModeOffset = 12;
const playfairModes = 4;
