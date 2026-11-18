/// The fixed values of the UKEY2 flavour Quick Share uses.
abstract final class Ukey2Constants {
  static const version = 1;
  static const randomLength = 32;

  /// What both sides agree to speak after the handshake.
  static const nextProtocol = 'AES_256_CBC-HMAC_SHA256';
}
