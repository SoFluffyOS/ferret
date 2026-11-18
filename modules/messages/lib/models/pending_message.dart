import 'package:messages/models/send_outcome.dart';

/// A reply typed here that the phone hasn't confirmed yet, or that failed.
class PendingMessage {
  const PendingMessage({
    required this.id,
    required this.text,
    required this.at,
    this.outcome,
  });

  final String id;
  final String text;
  final DateTime at;

  /// Null while sending.
  final SendOutcome? outcome;

  bool get isSending => outcome == null;

  bool get failed => outcome != null && outcome != SendOutcome.sent;

  PendingMessage withOutcome(SendOutcome? outcome) =>
      PendingMessage(id: id, text: text, at: at, outcome: outcome);
}
