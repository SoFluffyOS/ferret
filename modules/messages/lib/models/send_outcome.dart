import 'package:protocol/messages.dart';

/// How sending a text went, as the composer shows it.
enum SendOutcome {
  sent,

  /// The phone isn't connected.
  offline,
  noAccess,
  noRecipient,

  /// Group conversations need MMS, which only the phone's messaging app sends.
  group,
  noService,
  timeout,
  failed;

  static SendOutcome of(SendResult result) {
    if (result.ok) {
      return .sent;
    }

    return switch (result.failure) {
      .SEND_FAILURE_NO_ACCESS => .noAccess,
      .SEND_FAILURE_NO_RECIPIENT => .noRecipient,
      .SEND_FAILURE_GROUP => .group,
      .SEND_FAILURE_NO_SERVICE => .noService,
      .SEND_FAILURE_TIMEOUT => .timeout,
      _ => .failed,
    };
  }
}
