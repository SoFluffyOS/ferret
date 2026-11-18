/// How an adb command the user started went, such as pairing.
class AdbResult {
  const AdbResult({required this.succeeded, required this.message});

  final bool succeeded;

  /// adb's own answer, in English. For logs and details, not for a title.
  final String message;
}
