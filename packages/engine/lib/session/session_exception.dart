import 'package:protocol/protocol.dart';

/// A request that the other device answered with an error.
class RemoteErrorException implements Exception {
  const RemoteErrorException(this.code, this.message);

  final ErrorCode code;
  final String message;

  @override
  String toString() => 'RemoteErrorException(${code.name}): $message';
}

/// The session closed before a reply arrived.
class SessionClosedException implements Exception {
  const SessionClosedException();

  @override
  String toString() => 'SessionClosedException';
}
