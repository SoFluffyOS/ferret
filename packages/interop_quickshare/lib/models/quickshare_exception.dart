import 'package:interop_quickshare/models/quickshare_failure.dart';

/// A Quick Share connection couldn't go on. Messages never carry user
/// content, so they are safe to log.
class QuickShareException implements Exception {
  const QuickShareException(this.failure, [this.message = '']);

  final QuickShareFailure failure;
  final String message;

  @override
  String toString() => 'QuickShareException(${failure.name}): $message';
}
