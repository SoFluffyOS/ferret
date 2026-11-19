import 'dart:async';

import 'package:drop/services/outgoing_file.dart';
import 'package:drop/services/speed_meter.dart';

/// What the sender remembers about one outgoing transfer, so it can resume
/// it after a dropped session.
class OutgoingJob {
  OutgoingJob({
    required this.id,
    required this.deviceId,
    required this.files,
    this.text,
    this.temporary = false,
  });

  final String id;
  final String deviceId;
  final List<OutgoingFile> files;
  final String? text;

  /// The files are copies made for this transfer, such as shares from other
  /// apps, and are deleted once it finishes.
  final bool temporary;

  final SpeedMeter speed = SpeedMeter();

  /// Set when someone cancels; the send loop stops at the next chunk.
  bool cancelled = false;

  Completer<void>? _run;

  bool get isRunning => _run != null;

  /// Completes when the current run, if any, has stopped.
  Future<void> get stopped => _run?.future ?? Future.value();

  void markRunning() => _run = Completer<void>();

  void markStopped() {
    final run = _run;
    _run = null;
    run?.complete();
  }

  bool get hasFolders => files.any((file) => file.folder != null);

  /// Bytes of every file before [fileIndex].
  int bytesBefore(int fileIndex) =>
      files.take(fileIndex).fold(0, (sum, file) => sum + file.size);
}
