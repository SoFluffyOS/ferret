import 'package:crypto/crypto.dart';

/// LocalSend fingerprints: with HTTPS, the SHA-256 of the DER certificate
/// in hex.
abstract final class Fingerprints {
  static String ofCertificate(List<int> der) => sha256.convert(der).toString();

  /// Whether two fingerprints are the same, whatever their letter case.
  static bool same(String first, String second) =>
      first.toLowerCase() == second.toLowerCase();

  /// The first 16 characters in groups of four, such as `3F2A 91BC 07DE
  /// 44A1`, short enough to compare by eye on two screens.
  static String short(String fingerprint) {
    final head = switch (fingerprint.length > 16) {
      true => fingerprint.substring(0, 16),
      false => fingerprint,
    }.toUpperCase();
    return [
      for (var start = 0; start < head.length; start += 4)
        head.substring(
          start,
          switch (start + 4 < head.length) {
            true => start + 4,
            false => head.length,
          },
        ),
    ].join(' ');
  }
}
