import 'dart:async';
import 'dart:io';

import 'package:drop/models/models.dart';
import 'package:drop/services/part_hasher.dart';
import 'package:drop/services/speed_meter.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/drop.dart';

/// What the receiver keeps about one incoming transfer: where each part
/// file is, how much of it arrived, and what was saved.
class IncomingJob {
  IncomingJob({
    required this.id,
    required this.deviceId,
    required this.files,
    required this.names,
    required this.parts,
    List<String?>? folders,
  }) : folders = folders ?? List.filled(files.length, null),
       written = List.filled(files.length, 0),
       saved = List.filled(files.length, null);

  final String id;
  final String deviceId;
  final List<FileInfo> files;

  /// Safe local names, one per file.
  final List<String> names;

  /// The folder each file goes to inside the receive folder, null for a
  /// file sent on its own.
  final List<String?> folders;
  final Directory parts;

  /// Bytes written to each part file.
  final List<int> written;
  final List<ReceivedFile?> saved;
  final SpeedMeter speed = SpeedMeter();

  /// Hashes each part as it's written; let go with [close].
  final PartHasher hasher = PartHasher();

  /// Set once the transfer was cancelled; later chunks are refused.
  bool cancelled = false;

  /// Set after this side stopped on an error, so chunks still in flight
  /// are refused until a retry.
  bool halted = false;

  Future<void> _queue = Future.value();
  RandomAccessFile? _open;
  int? _openIndex;

  int sizeOf(int index) => files[index].size.toInt();

  int get receivedBytes => written.fold(0, (sum, bytes) => sum + bytes);

  bool get isComplete => saved.every((file) => file != null);

  File partFor(int index) => File(p.join(parts.path, '$id-$index.part'));

  /// Runs [work] after everything queued before it, in arrival order. The
  /// engine handles envelopes concurrently, so writes go through here.
  Future<T> enqueue<T>(Future<T> Function() work) {
    final result = _queue.then((_) => work());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Waits for queued work to finish.
  Future<void> get idle => _queue;

  /// Where the sender should continue: the first file not saved yet and the
  /// bytes already on disk for it.
  ({int fileIndex, int offset}) get resumePoint {
    for (var index = 0; index < files.length; index++) {
      if (saved[index] == null) {
        return (fileIndex: index, offset: written[index]);
      }
    }

    return (fileIndex: files.length, offset: 0);
  }

  /// The part file for [index], open for appending.
  Future<RandomAccessFile> openPart(int index) async {
    if ((_open, _openIndex) case (final open?, final openIndex)
        when openIndex == index) {
      return open;
    }

    await closePart();
    final part = partFor(index);
    final file = await part.open(mode: FileMode.append);
    final length = await file.length();
    if (length != written[index]) {
      await file.truncate(written[index]);
      await file.setPosition(written[index]);
    }

    _open = file;
    _openIndex = index;
    return file;
  }

  Future<void> closePart() async {
    final open = _open;
    _open = null;
    _openIndex = null;
    await open?.close();
  }

  /// Makes part [index] start over, such as after a failed checksum.
  Future<void> resetPart(int index) async {
    if (_openIndex == index) {
      await closePart();
    }

    written[index] = 0;
    hasher.forget(index);
    await _deleteQuietly(partFor(index));
  }

  /// Closes and deletes every part file.
  Future<void> discard() async {
    await closePart();
    for (var index = 0; index < files.length; index++) {
      if (saved[index] == null) {
        await _deleteQuietly(partFor(index));
      }
    }
  }

  /// Reconciles [written] with what is really on disk, before resuming.
  Future<void> syncWithDisk() async {
    await closePart();
    for (var index = 0; index < files.length; index++) {
      if (saved[index] != null) {
        continue;
      }

      final part = partFor(index);
      final length = switch (await part.exists()) {
        true => await part.length(),
        false => 0,
      };
      if (length < written[index]) {
        written[index] = length;
        hasher.forget(index);
      }
    }
  }

  /// Lets go of the part file and the hasher, once the job is over.
  Future<void> close() async {
    hasher.dispose();
    await closePart();
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } on FileSystemException {
      return;
    }
  }
}
