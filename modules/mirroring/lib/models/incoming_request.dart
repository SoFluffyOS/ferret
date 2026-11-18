import 'dart:async';

/// A device asking to show its screen on this computer, until its owner
/// answers or the question runs out.
class IncomingRequest {
  IncomingRequest({
    required this.receiverId,
    required this.deviceName,
    required this.askedAt,
  });

  final String receiverId;

  /// What the device calls itself. Nothing proves it.
  final String deviceName;
  final DateTime askedAt;

  final Completer<bool> _answer = .new();

  bool get isAnswered => _answer.isCompleted;

  /// Whether it was let in. No answer in time counts as a no.
  Future<bool> get answer => _answer.future;

  void complete(bool allowed) {
    if (!_answer.isCompleted) {
      _answer.complete(allowed);
    }
  }
}
