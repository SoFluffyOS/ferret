/// The 4-digit PIN Quick Share shows on both devices. It is made from
/// the handshake's authentication string, so matching PINs mean nobody
/// sits in the middle.
abstract final class QuickSharePin {
  static const _modulus = 9973;
  static const _multiplier = 31;

  static String of(List<int> authString) {
    var hash = 0;
    var weight = 1;
    for (final byte in authString) {
      // Phones do this sum with signed bytes and a remainder that keeps
      // the sign, so the same is done here.
      hash = (hash + byte.toSigned(8) * weight).remainder(_modulus);
      weight = (weight * _multiplier).remainder(_modulus);
    }

    return hash.abs().toString().padLeft(4, '0');
  }
}
