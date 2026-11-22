import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:drop/services/failure_codes.dart';
import 'package:drop/services/file_hasher.dart';
import 'package:drop/services/file_names.dart';
import 'package:drop/services/folder_plan.dart';
import 'package:drop/services/incoming_job.dart';
import 'package:drop/services/progress_throttle.dart';
import 'package:drop/services/receive_part.dart';
import 'package:drop/services/receive_store.dart';
import 'package:drop/services/transfer_registry.dart';
import 'package:engine/engine.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/drop.dart';

/// Receives files and text over Ferret sessions: answers offers, writes
/// chunks in order to part files, verifies each file's SHA-256 before
/// saving it, and asks to resume after a dropped session.
class DropReceiver {
  DropReceiver({
    required this.featureId,
    required this.registry,
    required this.store,
    required this.sessionFor,
    required this.deviceName,
    required this.autoAccept,
    this.answerTimeout = const Duration(seconds: 100),
  });

  final String featureId;
  final TransferRegistry registry;
  final ReceiveStore store;
  final Session? Function(String deviceId) sessionFor;
  final String Function(String deviceId) deviceName;

  /// Whether paired devices may send without asking.
  final bool Function() autoAccept;

  /// How long an offer waits for someone here to accept it. Shorter than the
  /// sender's offer timeout so it hears the answer.
  final Duration answerTimeout;

  /// Room left free on top of what an offer needs, so a transfer never
  /// fills the disk to the last byte.
  static const spaceMargin = 64 * 1024 * 1024;

  /// Verified files saved at the same time while later ones arrive.
  static const savesAtOnce = 4;

  static final _validId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
  static const _maxFiles = 10000;

  final Map<String, IncomingJob> _jobs = {};
  final Map<String, Completer<bool>> _answers = {};
  final Map<String, ProgressThrottle> _throttles = {};

  /// Whether a job for [id] is kept, so Retry can resume it.
  bool ownsJob(String id) => _jobs.containsKey(id);

  Future<TransferAnswer> onOffer(Session session, TransferOffer offer) async {
    final id = offer.transferId;
    final deviceId = session.remoteDeviceId;
    final plan = FolderPlan.parse([
      for (final file in offer.files) file.folder,
    ]);
    if (!_isValidOffer(offer) || plan == null) {
      return _decline(id, .DECLINE_REASON_INVALID);
    }

    if (_jobs[id] case final existing?) {
      if (existing.deviceId != deviceId) {
        return _decline(id, .DECLINE_REASON_INVALID);
      }

      await existing.settled;
      await existing.syncWithDisk();
      return _resumeAnswer(existing);
    }

    if (registry[id] case final known?) {
      if (known.deviceId != deviceId || known.isOutgoing) {
        return _decline(id, .DECLINE_REASON_INVALID);
      }

      // Only a finished transfer is answered as complete. One that was
      // cancelled stays so; one that never got an answer, such as an offer
      // cut off by a dropped link, is asked again.
      switch (known.status) {
        case .done:
          return TransferAnswer(
            transferId: id,
            accepted: true,
            fileIndex: known.files.length,
          );
        case .cancelled:
          return _decline(id, .DECLINE_REASON_DECLINED);
        default:
          break;
      }
    }

    final transfer = Transfer(
      id: id,
      direction: .incoming,
      deviceId: deviceId,
      deviceName: deviceName(deviceId),
      files: [
        for (final (index, file) in offer.files.indexed)
          TransferFile(
            name: FileNames.safe(file.name),
            size: file.size.toInt(),
            mime: file.mime,
            folder: plan.remote[index],
            modified: _modifiedOf(file),
          ),
      ],
      text: switch (offer.text.isEmpty) {
        true => null,
        false => offer.text,
      },
      status: .waiting,
      startedAt: DateTime.now(),
    );

    if (await _shortOfSpace(transfer) case final free?) {
      registry.put(
        transfer.copyWith(
          status: .failed,
          failure: .outOfSpace,
          freeBytes: free,
          needsAnswer: false,
        ),
      );
      // The free bytes ride along so the sender can say how short it is;
      // at least 1, as 0 reads as "not told" there.
      return TransferAnswer(
        transferId: id,
        reason: .DECLINE_REASON_STORAGE,
        offset: Int64(max(free, 1)),
      );
    }

    if (!autoAccept()) {
      final accepted = await _ask(transfer);
      if (!accepted.accepted) {
        return accepted;
      }
    }

    if (offer.files.isEmpty) {
      registry.put(transfer.copyWith(status: .done, needsAnswer: false));
      return TransferAnswer(transferId: id, accepted: true);
    }

    final List<ReceivePart> parts;
    final List<String?> folders;
    try {
      folders = await plan.place(store);
      parts = await store.partsFor(id, [
        for (final (index, file) in transfer.files.indexed)
          (name: file.name, mime: file.mime, folder: folders[index]),
      ]);
    } on Object catch (error) {
      printWarning(
        'Drop could not prepare the receive folder: ${error.runtimeType}',
      );
      registry.put(
        transfer.copyWith(
          status: .failed,
          failure: .storage,
          needsAnswer: false,
        ),
      );
      return _decline(id, .DECLINE_REASON_STORAGE);
    }

    final job = IncomingJob(
      id: id,
      deviceId: deviceId,
      files: offer.files,
      names: [for (final file in transfer.files) file.name],
      folders: folders,
      parts: parts,
    );
    await job.discard();
    _jobs[id] = job;
    registry.put(
      transfer.copyWith(
        status: .transferring,
        needsAnswer: false,
        files: [
          for (final (index, file) in transfer.files.indexed)
            file.copyWith(folder: folders[index]),
        ],
      ),
    );
    return TransferAnswer(transferId: id, accepted: true);
  }

  /// Writes [chunk] in order. Returns the acknowledgement for chunks sent
  /// as requests, or null when the transfer isn't accepting chunks.
  Future<ChunkReceived?> onChunk(Session session, Chunk chunk) {
    final job = _activeJob(session, chunk.transferId);
    if (job == null) {
      return Future.value();
    }

    return job.enqueue(() => _write(session, job, chunk));
  }

  Future<FileVerified> onFileComplete(
    Session session,
    FileComplete complete,
  ) async {
    final job = _activeJob(session, complete.transferId);
    if (job == null) {
      return FileVerified(
        transferId: complete.transferId,
        fileIndex: complete.fileIndex,
        reason: .FAILURE_REASON_UNKNOWN_TRANSFER,
      );
    }

    final check = await job.enqueue(() => _verify(job, complete));
    return check.answer;
  }

  Future<void> onTransferComplete(
    Session session,
    TransferComplete complete,
  ) async {
    final job = _activeJob(session, complete.transferId);
    if (job == null) {
      return;
    }

    await job.settled;
    if (job.isComplete) {
      _finish(job);
    }
  }

  /// The sender stopped the transfer.
  Future<void> onCancel(Session session, Cancel cancel) async {
    final id = cancel.transferId;
    final fromSender = registry[id]?.deviceId == session.remoteDeviceId;
    if (!fromSender) {
      return;
    }

    if (_answers.remove(id) case final pending?) {
      pending.complete(false);
      registry.update(
        id,
        (transfer) => transfer.copyWith(
          status: .cancelled,
          failure: .cancelledByPeer,
          needsAnswer: false,
        ),
      );
      return;
    }

    final job = _jobs[id];
    if (job == null || job.deviceId != session.remoteDeviceId) {
      return;
    }

    final failure = FailureCodes.fromWire(cancel.reason);
    final keepParts = switch (failure) {
      TransferFailure.storage ||
      TransferFailure.checksum ||
      TransferFailure.protocol => true,
      _ => false,
    };
    if (keepParts) {
      _set(
        job.id,
        (transfer) => transfer.copyWith(
          status: .failed,
          failure: failure,
          bytesPerSecond: 0,
        ),
      );
      return;
    }

    await _drop(job);
    _set(
      job.id,
      (transfer) => transfer.copyWith(
        status: switch (failure) {
          TransferFailure.cancelledByPeer => TransferStatus.cancelled,
          _ => TransferStatus.failed,
        },
        failure: failure,
        bytesPerSecond: 0,
      ),
    );
  }

  /// Answers an offer that waits for someone on this device.
  void answer(String id, {required bool accept}) =>
      _answers.remove(id)?.complete(accept);

  /// Cancels from this side and tells the sender.
  Future<void> cancel(String id) async {
    if (_answers.containsKey(id)) {
      answer(id, accept: false);
      return;
    }

    final job = _jobs[id];
    if (job == null) {
      if (registry[id]?.status == .done) {
        return;
      }

      _set(
        id,
        (transfer) => transfer.copyWith(status: .cancelled, bytesPerSecond: 0),
      );
      return;
    }

    await _drop(job);
    _set(
      id,
      (transfer) => transfer.copyWith(status: .cancelled, bytesPerSecond: 0),
    );
    if (sessionFor(job.deviceId) case final session?) {
      await _sendQuietly(
        session,
        Cancel(transferId: id, reason: .FAILURE_REASON_CANCELLED),
      );
    }
  }

  /// Asks the sender to continue where this side stopped.
  Future<void> retry(String id) async {
    final job = _jobs[id];
    if (job == null || job.cancelled) {
      return;
    }

    final session = sessionFor(job.deviceId);
    if (session == null) {
      _set(
        id,
        (transfer) =>
            transfer.copyWith(status: .failed, failure: .notConnected),
      );
      return;
    }

    await job.settled;
    await job.syncWithDisk();
    job
      ..halted = false
      ..speed.reset();
    final resume = job.resumeFromHere();
    _set(
      id,
      (transfer) => transfer.copyWith(
        status: .transferring,
        clearFailure: true,
        bytesDone: job.receivedBytes,
        bytesPerSecond: 0,
      ),
    );

    try {
      await session.send(
        featureId,
        ResumeRequest(
          transferId: id,
          fileIndex: resume.fileIndex,
          offset: Int64(resume.offset),
        ),
      );
    } on Object {
      _interrupt(job);
    }
  }

  void onSessionOpened(Session session) {
    for (final job in [..._jobs.values]) {
      final transfer = registry[job.id];
      if (job.deviceId != session.remoteDeviceId || transfer == null) {
        continue;
      }

      final resumable = switch (transfer.failure) {
        TransferFailure.disconnected || TransferFailure.notConnected => true,
        _ => false,
      };
      if (transfer.status == .failed && resumable) {
        unawaited(retry(job.id));
      }
    }
  }

  void onSessionClosed(Session session) {
    for (final entry in [..._answers.entries]) {
      if (registry[entry.key]?.deviceId != session.remoteDeviceId) {
        continue;
      }

      _answers.remove(entry.key);
      registry.update(
        entry.key,
        (transfer) => transfer.copyWith(
          status: .failed,
          failure: .disconnected,
          needsAnswer: false,
        ),
      );
      entry.value.complete(false);
    }

    for (final job in [..._jobs.values]) {
      if (job.deviceId != session.remoteDeviceId) {
        continue;
      }

      if (registry[job.id]?.status.isActive ?? false) {
        _interrupt(job);
      }
    }
  }

  Future<void> dispose() async {
    for (final job in _jobs.values) {
      await job.close();
    }
  }

  Future<ChunkReceived?> _write(
    Session session,
    IncomingJob job,
    Chunk chunk,
  ) async {
    if (job.cancelled) {
      return null;
    }

    if (job.halted) {
      // A file before this one didn't check out or couldn't be saved; the
      // sender hears so from its answer. Until then its next file's chunks
      // are let through unwritten, so it isn't left waiting on them.
      return ChunkReceived(
        transferId: job.id,
        fileIndex: chunk.fileIndex,
        offset: Int64(chunk.offset.toInt() + chunk.data.length),
      );
    }

    final index = chunk.fileIndex;
    final offset = chunk.offset.toInt();
    if (index < job.files.length && job.saved[index] != null) {
      // Saves finish out of order, so a resume can start before a file
      // that is already here. Its bytes are let through unwritten.
      return ChunkReceived(
        transferId: job.id,
        fileIndex: index,
        offset: Int64(offset + chunk.data.length),
      );
    }

    final valid =
        index < job.files.length &&
        job.saved[index] == null &&
        offset == job.written[index] &&
        offset + chunk.data.length <= job.sizeOf(index);
    if (!valid) {
      await _stop(session, job, .protocol);
      return null;
    }

    try {
      final part = await job.openPart(index);
      await part.write(chunk.data);
      job.hasher.add(index, offset, chunk.data);
    } on FileSystemException catch (error) {
      printWarning('Drop could not write a received file', error.osError);
      await _stop(session, job, .storage);
      return null;
    }

    job.written[index] += chunk.data.length;
    job.speed.add(job.receivedBytes);
    final throttle = _throttles.putIfAbsent(job.id, ProgressThrottle.new);
    if (throttle.shouldEmit) {
      _set(
        job.id,
        (transfer) => transfer.copyWith(
          bytesDone: job.receivedBytes,
          bytesPerSecond: job.speed.bytesPerSecond,
        ),
      );
    }

    return ChunkReceived(
      transferId: job.id,
      fileIndex: index,
      offset: Int64(job.written[index]),
    );
  }

  /// Checks file [FileComplete.fileIndex] in the job's queue, then saves it
  /// outside the queue, so the next file's chunks are written while this
  /// one is put in place. The answer comes once it is saved.
  Future<({Future<FileVerified> answer})> _verify(
    IncomingJob job,
    FileComplete complete,
  ) async {
    final index = complete.fileIndex;
    ({Future<FileVerified> answer}) answer({FailureReason? reason}) => (
      answer: Future.value(_verified(job, index, reason: reason)),
    );

    if (job.cancelled || index >= job.files.length) {
      return answer(reason: .FAILURE_REASON_PROTOCOL);
    }

    if (job.saved[index] != null) {
      return answer();
    }

    if (job.halted) {
      // A file before this one failed and the sender stops at its answer;
      // this one's bytes were let through unwritten.
      return answer(reason: .FAILURE_REASON_CANCELLED);
    }

    if (job.savingOf(index) case final saving?) {
      return (answer: saving);
    }

    if (job.written[index] != job.sizeOf(index)) {
      return answer(reason: .FAILURE_REASON_PROTOCOL);
    }

    await job.closePart();
    final total = job.files.fold(0, (sum, file) => sum + file.size.toInt());
    _set(
      job.id,
      (transfer) => transfer.copyWith(
        status: switch (job.receivedBytes >= total) {
          true => .verifying,
          false => null,
        },
        bytesDone: job.receivedBytes,
      ),
    );

    try {
      final hash =
          await job.hasher.digest(index, job.written[index]) ??
          await job.parts[index].hash();
      final promised = job.files[index].sha256;
      final matches =
          FileHasher.same(hash, complete.sha256) &&
          (promised.isEmpty || FileHasher.same(hash, promised));
      if (!matches) {
        job.halted = true;
        await job.resetPart(index);
        _set(
          job.id,
          (transfer) => transfer.copyWith(
            status: .failed,
            failure: .checksum,
            bytesDone: job.receivedBytes,
            bytesPerSecond: 0,
          ),
        );
        return answer(reason: .FAILURE_REASON_CHECKSUM);
      }
    } on Object catch (error) {
      return answer(reason: _failStorage(job, error));
    }

    return (answer: job.track(index, _save(job, index)));
  }

  Future<FileVerified> _save(IncomingJob job, int index) =>
      job.withSaveSlot(savesAtOnce, () async {
        if (job.cancelled) {
          return _verified(job, index, reason: .FAILURE_REASON_CANCELLED);
        }

        final ReceivedFile saved;
        try {
          saved = await job.parts[index].save(
            modified: _modifiedOf(job.files[index]),
          );
        } on Object catch (error) {
          if (job.cancelled) {
            return _verified(job, index, reason: .FAILURE_REASON_CANCELLED);
          }

          return _verified(job, index, reason: _failStorage(job, error));
        }

        job.saved[index] = saved;
        _set(
          job.id,
          (transfer) => transfer.copyWith(
            files: [
              for (final (fileIndex, file) in transfer.files.indexed)
                switch (fileIndex == index) {
                  true => file.copyWith(
                    name: saved.name,
                    location: saved.location,
                  ),
                  false => file,
                },
            ],
          ),
        );
        if (job.isComplete && !job.cancelled) {
          _finish(job);
        }

        return _verified(job, index);
      });

  /// Stops [job] after a file couldn't be saved; chunks still in flight
  /// are refused until a retry.
  FailureReason _failStorage(IncomingJob job, Object error) {
    printWarning('Drop could not save a received file: ${error.runtimeType}');
    job.halted = true;
    _set(
      job.id,
      (transfer) => transfer.copyWith(
        status: .failed,
        failure: .storage,
        bytesPerSecond: 0,
      ),
    );
    return .FAILURE_REASON_STORAGE;
  }

  FileVerified _verified(
    IncomingJob job,
    int index, {
    FailureReason? reason,
  }) => FileVerified(
    transferId: job.id,
    fileIndex: index,
    ok: reason == null,
    reason: reason,
  );

  /// The bytes free here when [transfer] doesn't fit, or null when it does
  /// or the free space can't be told. Files are written where they end up,
  /// so each needs its room once.
  Future<int?> _shortOfSpace(Transfer transfer) async {
    if (transfer.files.isEmpty) {
      return null;
    }

    final int? free;
    try {
      free = await store.freeBytes();
    } on Object catch (error) {
      printDebug('Drop could not read the free space: ${error.runtimeType}');
      return null;
    }

    if (free == null) {
      return null;
    }

    final needed = transfer.totalBytes + spaceMargin;
    return switch (free < needed) {
      true => free,
      false => null,
    };
  }

  Future<TransferAnswer> _ask(Transfer transfer) async {
    final pending = Completer<bool>();
    _answers[transfer.id] = pending;
    registry.put(transfer.copyWith(needsAnswer: true));

    final accepted = await pending.future.timeout(
      answerTimeout,
      onTimeout: () => false,
    );
    final timedOut = _answers.remove(transfer.id) != null;
    if (accepted) {
      return TransferAnswer(transferId: transfer.id, accepted: true);
    }

    if (timedOut) {
      registry.update(
        transfer.id,
        (current) => current.copyWith(
          status: .failed,
          failure: .timedOut,
          needsAnswer: false,
        ),
      );
      return _decline(transfer.id, .DECLINE_REASON_TIMEOUT);
    }

    registry.update(
      transfer.id,
      (current) => switch (current.status) {
        TransferStatus.waiting => current.copyWith(
          status: .cancelled,
          failure: .declined,
          needsAnswer: false,
        ),
        _ => current,
      },
    );
    return _decline(transfer.id, .DECLINE_REASON_DECLINED);
  }

  TransferAnswer _resumeAnswer(IncomingJob job) {
    job
      ..halted = false
      ..speed.reset();
    final resume = job.resumeFromHere();
    _set(
      job.id,
      (transfer) => transfer.copyWith(
        status: .transferring,
        clearFailure: true,
        bytesDone: job.receivedBytes,
        bytesPerSecond: 0,
      ),
    );
    return TransferAnswer(
      transferId: job.id,
      accepted: true,
      fileIndex: resume.fileIndex,
      offset: Int64(resume.offset),
    );
  }

  void _finish(IncomingJob job) {
    if (_jobs.remove(job.id) == null) {
      return;
    }

    job.hasher.dispose();
    _throttles.remove(job.id);
    _set(
      job.id,
      (transfer) => transfer.copyWith(
        status: .done,
        bytesDone: transfer.totalBytes,
        bytesPerSecond: 0,
      ),
    );
  }

  /// The session dropped. Chunks that already arrived are still written;
  /// the part closes after them.
  void _interrupt(IncomingJob job) {
    unawaited(job.enqueue(job.closePart));
    _set(
      job.id,
      (transfer) => transfer.copyWith(
        status: .failed,
        failure: .disconnected,
        bytesDone: job.receivedBytes,
        bytesPerSecond: 0,
      ),
    );
  }

  /// Stops after an error on this side and tells the sender why.
  Future<void> _stop(
    Session session,
    IncomingJob job,
    TransferFailure failure,
  ) async {
    job.halted = true;
    await job.closePart();
    _set(
      job.id,
      (transfer) => transfer.copyWith(
        status: .failed,
        failure: failure,
        bytesPerSecond: 0,
      ),
    );
    await _sendQuietly(
      session,
      Cancel(transferId: job.id, reason: FailureCodes.toWire(failure)),
    );
  }

  /// Forgets [job] for good and deletes its parts.
  Future<void> _drop(IncomingJob job) async {
    job.cancelled = true;
    _jobs.remove(job.id);
    _throttles.remove(job.id);
    await job.enqueue(job.discard);
    job.hasher.dispose();
  }

  IncomingJob? _activeJob(Session session, String id) {
    final job = _jobs[id];
    if (job == null ||
        job.deviceId != session.remoteDeviceId ||
        job.cancelled) {
      return null;
    }

    return job;
  }

  bool _isValidOffer(TransferOffer offer) {
    if (!_validId.hasMatch(offer.transferId)) {
      return false;
    }

    if (offer.files.isEmpty && offer.text.isEmpty) {
      return false;
    }

    if (offer.files.length > _maxFiles) {
      return false;
    }

    return offer.files.every(
      (file) => file.name.trim().isNotEmpty && file.size >= 0,
    );
  }

  DateTime? _modifiedOf(FileInfo file) => switch (file.modifiedMs.toInt()) {
    final millis when millis > 0 => DateTime.fromMillisecondsSinceEpoch(
      millis,
    ),
    _ => null,
  };

  TransferAnswer _decline(String id, DeclineReason reason) =>
      TransferAnswer(transferId: id, reason: reason);

  void _set(String id, Transfer Function(Transfer current) change) =>
      registry.update(id, change);

  Future<void> _sendQuietly(Session session, Cancel cancel) async {
    try {
      await session.send(featureId, cancel);
    } on Object {
      return;
    }
  }
}
