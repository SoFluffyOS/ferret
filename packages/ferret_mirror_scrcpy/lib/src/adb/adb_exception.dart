/// An adb command failed.
class AdbException implements Exception {
  const AdbException(this.message);

  /// adb's own words, for logs.
  final String message;

  @override
  String toString() => 'AdbException: $message';
}
