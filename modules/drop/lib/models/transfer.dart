import 'package:drop/models/localsend_origin.dart';
import 'package:drop/models/transfer_direction.dart';
import 'package:drop/models/transfer_failure.dart';
import 'package:drop/models/transfer_file.dart';
import 'package:drop/models/transfer_status.dart';

/// A snapshot of one transfer of files or text with another device. Each
/// change replaces the snapshot, so the UI can compare them.
class Transfer {
  const Transfer({
    required this.id,
    required this.direction,
    required this.deviceId,
    required this.deviceName,
    required this.files,
    required this.status,
    required this.startedAt,
    this.text,
    this.failure,
    this.bytesDone = 0,
    this.bytesPerSecond = 0,
    this.needsAnswer = false,
    this.localSend,
  });

  final String id;
  final TransferDirection direction;
  final String deviceId;
  final String deviceName;
  final List<TransferFile> files;
  final String? text;
  final TransferStatus status;
  final TransferFailure? failure;
  final int bytesDone;

  /// Recent speed, or 0 when unknown.
  final double bytesPerSecond;
  final DateTime startedAt;

  /// An incoming offer waiting for someone on this device to accept it.
  final bool needsAnswer;

  /// Set when the other side is a LocalSend device instead of a paired
  /// Ferret device.
  final LocalSendOrigin? localSend;

  bool get isLocalSend => localSend != null;

  int get totalBytes => files.fold(0, (sum, file) => sum + file.size);

  bool get isText => files.isEmpty;

  bool get isOutgoing => direction == TransferDirection.outgoing;

  /// 0 to 1.
  double get progress {
    final total = totalBytes;
    if (total <= 0) {
      return switch (status) {
        TransferStatus.done => 1,
        _ => 0,
      };
    }

    return (bytesDone / total).clamp(0, 1).toDouble();
  }

  /// Time left at the recent speed, or null when unknown.
  Duration? get eta {
    if (status != TransferStatus.transferring || bytesPerSecond <= 0) {
      return null;
    }

    final seconds = (totalBytes - bytesDone) / bytesPerSecond;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// Whether Retry can pick this transfer up again.
  bool get canRetry => switch (status) {
    TransferStatus.failed => switch (failure) {
      TransferFailure.declined ||
      TransferFailure.unsupported ||
      TransferFailure.cancelledByPeer ||
      TransferFailure.pinRequired ||
      TransferFailure.tooManyAttempts ||
      TransferFailure.busy ||
      TransferFailure.unreachable ||
      TransferFailure.untrusted => isOutgoing,
      _ => !isLocalSend || isOutgoing,
    },
    _ => false,
  };

  Transfer copyWith({
    List<TransferFile>? files,
    String? text,
    TransferStatus? status,
    TransferFailure? failure,
    bool clearFailure = false,
    int? bytesDone,
    double? bytesPerSecond,
    bool? needsAnswer,
  }) => Transfer(
    id: id,
    direction: direction,
    deviceId: deviceId,
    deviceName: deviceName,
    files: files ?? this.files,
    text: text ?? this.text,
    status: status ?? this.status,
    failure: switch (clearFailure) {
      true => null,
      false => failure ?? this.failure,
    },
    bytesDone: bytesDone ?? this.bytesDone,
    bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
    startedAt: startedAt,
    needsAnswer: needsAnswer ?? this.needsAnswer,
    localSend: localSend,
  );
}
