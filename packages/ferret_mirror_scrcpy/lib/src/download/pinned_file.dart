/// A file to fetch from the internet, and the SHA-256 it must have.
class PinnedFile {
  const PinnedFile({
    required this.url,
    required this.sha256,
    required this.fileName,
  });

  final String url;

  /// Lowercase hex.
  final String sha256;
  final String fileName;
}
