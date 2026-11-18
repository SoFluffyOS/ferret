import 'package:drop/models/models.dart';
import 'package:protocol/drop.dart';

/// Maps Drop's wire reasons to what the UI explains, and back.
abstract final class FailureCodes {
  static TransferFailure fromDecline(DeclineReason reason) => switch (reason) {
    .DECLINE_REASON_TIMEOUT => .timedOut,
    .DECLINE_REASON_STORAGE => .storage,
    .DECLINE_REASON_UNKNOWN_TRANSFER => .unknownTransfer,
    .DECLINE_REASON_INVALID => .protocol,
    _ => .declined,
  };

  static TransferFailure fromWire(FailureReason reason) => switch (reason) {
    .FAILURE_REASON_CHECKSUM => .checksum,
    .FAILURE_REASON_STORAGE => .storage,
    .FAILURE_REASON_SOURCE_CHANGED => .sourceChanged,
    .FAILURE_REASON_PROTOCOL => .protocol,
    .FAILURE_REASON_UNKNOWN_TRANSFER => .unknownTransfer,
    _ => .cancelledByPeer,
  };

  static FailureReason toWire(TransferFailure failure) => switch (failure) {
    .checksum => .FAILURE_REASON_CHECKSUM,
    .storage => .FAILURE_REASON_STORAGE,
    .sourceChanged => .FAILURE_REASON_SOURCE_CHANGED,
    .protocol => .FAILURE_REASON_PROTOCOL,
    .unknownTransfer => .FAILURE_REASON_UNKNOWN_TRANSFER,
    _ => .FAILURE_REASON_CANCELLED,
  };
}
