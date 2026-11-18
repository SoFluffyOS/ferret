/// The server that ships with the app isn't the one pinned, or couldn't be
/// put on disk.
class ScrcpyServerException implements Exception {
  const ScrcpyServerException(this.message);

  final String message;

  @override
  String toString() => 'ScrcpyServerException: $message';
}
