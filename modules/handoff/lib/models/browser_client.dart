/// A browser extension the user allowed to use Ferret. Only a hash of its
/// token is kept, so the settings file never holds a usable secret.
class BrowserClient {
  const BrowserClient({
    required this.id,
    required this.name,
    required this.origin,
    required this.tokenHash,
    required this.pairedAt,
  });

  final String id;

  /// What the extension calls its browser, such as "Firefox".
  final String name;

  /// The extension's origin, such as `moz-extension://…`. The token only
  /// works from this origin.
  final String origin;
  final String tokenHash;
  final DateTime pairedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'origin': origin,
    'token_hash': tokenHash,
    'paired_at_ms': pairedAt.millisecondsSinceEpoch,
  };

  static BrowserClient? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'origin': final String origin,
      'token_hash': final String tokenHash,
      'paired_at_ms': final int pairedAtMs,
    }) {
      return BrowserClient(
        id: id,
        name: name,
        origin: origin,
        tokenHash: tokenHash,
        pairedAt: .fromMillisecondsSinceEpoch(pairedAtMs),
      );
    }

    return null;
  }
}
