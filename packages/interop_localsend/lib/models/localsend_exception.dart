import 'package:interop_localsend/models/localsend_failure.dart';

/// A LocalSend request that failed, with the reason to explain.
class LocalSendException implements Exception {
  const LocalSendException(this.failure, {this.statusCode});

  final LocalSendFailure failure;

  /// The HTTP status, when the other device answered.
  final int? statusCode;

  @override
  String toString() => switch (statusCode) {
    final status? => 'LocalSendException(${failure.name}, HTTP $status)',
    null => 'LocalSendException(${failure.name})',
  };
}
