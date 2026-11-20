import 'dart:async';

/// A device asking to show its screen on this computer, or to use it as
/// its extra display, until its owner answers or the question runs out.
class IncomingRequest {
  IncomingRequest({
    required this.receiverId,
    required this.deviceName,
    required this.askedAt,
    required this.deadline,
    this.deviceId,
    this.display = false,
  });

  final String receiverId;

  /// The paired device asking, when it asks over Ferret.
  final String? deviceId;

  /// It asks to be shown as an extra display of its desktop, not its
  /// screen.
  final bool display;

  /// What the device calls itself. Nothing proves it.
  final String deviceName;
  final DateTime askedAt;

  /// When the question runs out and counts as a no.
  final DateTime deadline;

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
