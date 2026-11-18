/// A pinned file couldn't be fetched, or wasn't the file expected.
class DownloadException implements Exception {
  const DownloadException(this.message);

  final String message;

  @override
  String toString() => 'DownloadException: $message';
}
