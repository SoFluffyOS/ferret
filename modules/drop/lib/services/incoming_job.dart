import 'dart:async';

import 'package:drop/models/models.dart';
import 'package:drop/services/part_hasher.dart';
import 'package:drop/services/receive_part.dart';
import 'package:drop/services/speed_meter.dart';
import 'package:protocol/drop.dart';

/// What the receiver keeps about one incoming transfer: where each file is
/// written while it arrives, how much of it arrived, and what was saved.
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

  /// Where each file is written while it arrives, one per file.
  final List<ReceivePart> parts;

  /// Bytes written to each part.
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
  PartWriter? _open;
  int? _openIndex;

  /// Verified files being saved, by index, with the answer each one gets.
  final Map<int, Future<FileVerified>> _saving = {};
  int _savesRunning = 0;
  final List<Completer<void>> _saveSlots = [];

  int sizeOf(int index) => files[index].size.toInt();

  int get receivedBytes => written.fold(0, (sum, bytes) => sum + bytes);

  bool get isComplete => saved.every((file) => file != null);

  /// Runs [work] after everything queued before it, in arrival order. The
  /// engine handles envelopes concurrently, so writes go through here.
  Future<T> enqueue<T>(Future<T> Function() work) {
    final result = _queue.then((_) => work());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Waits for queued work to finish.
  Future<void> get idle => _queue;

  /// Waits for queued work and for every save under way, so what is on
  /// disk and in [saved] agrees.
  Future<void> get settled async {
    await _queue;
    while (_saving.isNotEmpty) {
      await Future.wait([..._saving.values]);
    }
  }

  /// The answer for file [index] while it is being saved, or null.
  Future<FileVerified>? savingOf(int index) => _saving[index];

  /// Keeps [save] as file [index]'s answer until it is done.
  Future<FileVerified> track(int index, Future<FileVerified> save) {
    _saving[index] = save;
    return save.whenComplete(() => _saving.remove(index));
  }

  /// Runs [work] once fewer than [limit] saves run, so a burst of small
  /// files doesn't start hundreds of copies at once.
  Future<T> withSaveSlot<T>(int limit, Future<T> Function() work) async {
    while (_savesRunning >= limit) {
      final slot = Completer<void>();
      _saveSlots.add(slot);
      await slot.future;
    }

    _savesRunning++;
    try {
      return await work();
    } finally {
      _savesRunning--;
      if (_saveSlots.isNotEmpty) {
        _saveSlots.removeAt(0).complete();
      }
    }
  }

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

  /// [resumePoint], once files after it that aren't saved start over: the
  /// sender sends every later file from its start. Call it once [settled].
  ({int fileIndex, int offset}) resumeFromHere() {
    final resume = resumePoint;
    for (var index = resume.fileIndex + 1; index < files.length; index++) {
      if (saved[index] == null && written[index] > 0) {
        written[index] = 0;
        hasher.forget(index);
      }
    }

    return resume;
  }

  /// Part [index], open to write after the bytes already there.
  Future<PartWriter> openPart(int index) async {
    if ((_open, _openIndex) case (final open?, final openIndex)
        when openIndex == index) {
      return open;
    }

    await closePart();
    final writer = await parts[index].open(written[index]);
    _open = writer;
    _openIndex = index;
    return writer;
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
    await parts[index].delete();
  }

  /// Closes and deletes every part not saved yet.
  Future<void> discard() async {
    await closePart();
    for (var index = 0; index < files.length; index++) {
      if (saved[index] == null) {
        await parts[index].delete();
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

      final length = await parts[index].length();
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
}
