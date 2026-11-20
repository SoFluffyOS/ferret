import 'package:drop/models/localsend_origin.dart';
import 'package:drop/models/quickshare_origin.dart';
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
    this.quickShare,
    this.skipped = 0,
    this.freeBytes,
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

  /// Set when the other side is a phone sending with Quick Share.
  final QuickShareOrigin? quickShare;

  /// Links and special files in a sent folder that were left out.
  final int skipped;

  /// The room the receiving device had when it turned the files down for
  /// lack of it ([TransferFailure.outOfSpace]).
  final int? freeBytes;

  bool get isLocalSend => localSend != null;

  bool get isQuickShare => quickShare != null;

  /// Whether the other side isn't a paired Ferret device, so nothing it
  /// says about itself is proven.
  bool get isUnpaired => isLocalSend || isQuickShare;

  int get totalBytes => files.fold(0, (sum, file) => sum + file.size);

  /// The folder every file sits in, when a single folder travels, so the
  /// transfer reads as that folder. Null for loose files or a mix.
  String? get folderName {
    final roots = {for (final file in files) file.rootFolder}.toList();
    if (roots case [final String root]) {
      return root;
    }

    return null;
  }

  bool get isFolder => folderName != null;

  /// Where the folder that travelled is on this device, as a path: the
  /// source when sending, the new folder once something was saved. Null
  /// for loose files and for `content://` locations, which have no folder
  /// path.
  String? get folderLocation {
    if (folderName == null) {
      return null;
    }

    for (final file in files) {
      final location = file.location;
      final folder = file.folder;
      if (location == null || folder == null || location.contains('://')) {
        continue;
      }

      final separator = switch (location.contains(r'\')) {
        true => r'\',
        false => '/',
      };
      final parts = location.split(separator);
      final depth = folder.split('/').length;
      if (parts.length <= depth + 1) {
        continue;
      }

      return parts.take(parts.length - depth).join(separator);
    }

    return null;
  }

  /// Files fully across, counted from [bytesDone]: files go one after the
  /// other, so every file that ends before it is done.
  int get filesDone {
    if (status == TransferStatus.done) {
      return files.length;
    }

    var end = 0;
    var done = 0;
    for (final file in files) {
      end += file.size;
      if (end > bytesDone || (file.size == 0 && end == bytesDone)) {
        return done;
      }

      done++;
    }

    return done;
  }

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

  /// Stopped only because the device went away: it goes on by itself, from
  /// where it stopped, once the device is back. LocalSend and Quick Share
  /// can't resume, so theirs never pause.
  bool get isPaused => switch ((status, failure)) {
    (
      TransferStatus.failed,
      TransferFailure.disconnected || TransferFailure.notConnected,
    ) =>
      !isLocalSend && !isQuickShare,
    _ => false,
  };

  /// Whether Retry can pick this transfer up again.
  bool get canRetry => switch (status) {
    TransferStatus.failed => switch (failure) {
      TransferFailure.declined ||
      TransferFailure.unsupported ||
      TransferFailure.foldersUnsupported ||
      TransferFailure.cancelledByPeer ||
      TransferFailure.pinRequired ||
      TransferFailure.tooManyAttempts ||
      TransferFailure.busy ||
      TransferFailure.unreachable ||
      TransferFailure.untrusted ||
      TransferFailure.outOfSpace => isOutgoing,
      _ => !isUnpaired || isOutgoing,
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
    int? freeBytes,
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
    quickShare: quickShare,
    skipped: skipped,
    freeBytes: switch (clearFailure) {
      true => null,
      false => freeBytes ?? this.freeBytes,
    },
  );
}
