import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:core/core.dart';
import 'package:crypto/crypto.dart';
import 'package:drop/models/models.dart';
import 'package:drop/services/digest_sink.dart';
import 'package:drop/services/failure_codes.dart';
import 'package:drop/services/outgoing_file.dart';
import 'package:drop/services/outgoing_job.dart';
import 'package:drop/services/progress_throttle.dart';
import 'package:drop/services/transfer_ids.dart';
import 'package:drop/services/transfer_registry.dart';
import 'package:engine/engine.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protocol/drop.dart';
import 'package:protocol/protocol.dart' show Envelope;

/// Sends files and text over Ferret sessions: offers, streams chunks with
/// backpressure, waits for the receiver to verify each file, and resumes.
class DropSender {
  DropSender({
    required this.featureId,
    required this.registry,
    required this.sessionFor,
    required this.deviceName,
    this.chunkSize = defaultChunkSize,
    this.ackEvery = defaultAckEvery,
    this.offerTimeout = const Duration(minutes: 2),
    this.ackTimeout = const Duration(seconds: 60),
    this.resumeGrace = const Duration(seconds: 3),
  });

  static const defaultChunkSize = 256 * 1024;

  /// Every this many chunks one is sent as a request, and the next window
  /// waits for its answer, so at most two windows are in flight.
  static const defaultAckEvery = 8;

  /// The flag a receiver's drop `FeatureSupport` carries when it can build
  /// a sent folder's tree. Older receivers would flatten it.
  static const foldersFlag = 'folders';

  final String featureId;
  final TransferRegistry registry;
  final Session? Function(String deviceId) sessionFor;
  final String Function(String deviceId) deviceName;
  final int chunkSize;
  final int ackEvery;
  final Duration offerTimeout;
  final Duration ackTimeout;

  /// How long a device that came back gets to ask to resume on its own
  /// before this side offers again. An offer also resumes, but the
  /// receiver knows best where it stopped.
  final Duration resumeGrace;

  final Map<String, OutgoingJob> _jobs = {};

  /// Offers [files] to [deviceId] and sends them once accepted. [skipped]
  /// counts what a sent folder held but can't travel, such as links.
  Transfer sendFiles(
    String deviceId,
    List<OutgoingFile> files, {
    bool temporary = false,
    int skipped = 0,
  }) => _start(
    OutgoingJob(
      id: TransferIds.next(),
      deviceId: deviceId,
      files: files,
      temporary: temporary,
    ),
    skipped: skipped,
  );

  Transfer sendText(String deviceId, String text) => _start(
    OutgoingJob(
      id: TransferIds.next(),
      deviceId: deviceId,
      files: const [],
      text: text,
    ),
  );

  bool owns(String id) => _jobs.containsKey(id);

  /// Offers the transfer again. The receiver answers where to continue.
  Future<void> retry(String id) async {
    final job = _jobs[id];
    if (job == null) {
      return;
    }

    await job.stopped;
    job.cancelled = false;
    _run(job, offer: true);
  }

  Future<void> cancel(String id) async {
    final job = _jobs[id];
    if (job == null) {
      return;
    }

    job.cancelled = true;
    _set(job, (transfer) => transfer.copyWith(status: .cancelled));
    await _forget(job);

    final session = sessionFor(job.deviceId);
    if (session == null) {
      return;
    }

    await _sendQuietly(
      session,
      Cancel(transferId: id, reason: .FAILURE_REASON_CANCELLED),
    );
  }

  /// [session]'s device is back: every send to it that paused because the
  /// link dropped, or that started while it was away, goes on by itself.
  void onSessionOpened(Session session) {
    final paused = [
      for (final job in _jobs.values)
        if (job.deviceId == session.remoteDeviceId &&
            !job.cancelled &&
            (registry[job.id]?.isPaused ?? false))
          job,
    ];
    if (paused.isEmpty) {
      return;
    }

    unawaited(
      Future<void>.delayed(resumeGrace, () async {
        for (final job in paused) {
          final stillPaused = registry[job.id]?.isPaused ?? false;
          if (job.cancelled || !stillPaused || !_jobs.containsKey(job.id)) {
            continue;
          }

          await retry(job.id);
        }
      }),
    );
  }

  /// The receiver came back after a dropped session and asks to continue.
  Future<void> onResumeRequest(Session session, ResumeRequest request) async {
    final job = _jobs[request.transferId];
    if (job == null || job.deviceId != session.remoteDeviceId) {
      await _sendQuietly(
        session,
        Cancel(
          transferId: request.transferId,
          reason: .FAILURE_REASON_UNKNOWN_TRANSFER,
        ),
      );
      return;
    }

    if (job.cancelled) {
      return;
    }

    await job.stopped;
    if (!_jobs.containsKey(job.id) || job.cancelled) {
      return;
    }

    _run(
      job,
      offer: false,
      fileIndex: request.fileIndex,
      offset: request.offset.toInt(),
    );
  }

  /// The receiver stopped the transfer.
  Future<void> onCancel(Session session, Cancel cancel) async {
    final job = _jobs[cancel.transferId];
    if (job == null || job.deviceId != session.remoteDeviceId) {
      return;
    }

    job.cancelled = true;
    if (cancel.reason == .FAILURE_REASON_CANCELLED) {
      _set(
        job,
        (transfer) =>
            transfer.copyWith(status: .cancelled, failure: .cancelledByPeer),
      );
      await _forget(job);
      return;
    }

    _set(
      job,
      (transfer) => transfer.copyWith(
        status: .failed,
        failure: FailureCodes.fromWire(cancel.reason),
      ),
    );
  }

  Transfer _start(OutgoingJob job, {int skipped = 0}) {
    _jobs[job.id] = job;
    final transfer = Transfer(
      id: job.id,
      direction: .outgoing,
      deviceId: job.deviceId,
      deviceName: deviceName(job.deviceId),
      files: [
        for (final file in job.files)
          TransferFile(
            name: file.name,
            size: file.size,
            mime: file.mime,
            location: file.path,
            folder: file.folder,
            modified: file.modified,
          ),
      ],
      text: job.text,
      status: .waiting,
      startedAt: DateTime.now(),
      skipped: skipped,
    );
    registry.put(transfer);
    _run(job, offer: true);
    return transfer;
  }

  void _run(
    OutgoingJob job, {
    required bool offer,
    int fileIndex = 0,
    int offset = 0,
  }) {
    if (job.isRunning) {
      return;
    }

    job.markRunning();
    unawaited(
      _send(
        job,
        offer: offer,
        fileIndex: fileIndex,
        offset: offset,
      ).whenComplete(job.markStopped),
    );
  }

  Future<void> _send(
    OutgoingJob job, {
    required bool offer,
    required int fileIndex,
    required int offset,
  }) async {
    final session = sessionFor(job.deviceId);
    if (session == null) {
      _fail(job, .notConnected);
      return;
    }

    if (!session.supports(featureId)) {
      _fail(job, .unsupported);
      return;
    }

    final takesFolders =
        session.remoteFeature(featureId)?.flags.contains(foldersFlag) ?? false;
    if (job.hasFolders && !takesFolders) {
      _fail(job, .foldersUnsupported);
      return;
    }

    try {
      var start = (fileIndex: fileIndex, offset: offset);
      if (offer) {
        _set(
          job,
          (transfer) => transfer.copyWith(status: .waiting, clearFailure: true),
        );
        final answer = await _whileOpen(
          session,
          session.call(
            featureId,
            _offerOf(job),
            TransferAnswer.new,
            timeout: offerTimeout,
          ),
        );
        if (!answer.accepted) {
          _fail(job, FailureCodes.fromDecline(answer.reason));
          return;
        }

        start = (fileIndex: answer.fileIndex, offset: answer.offset.toInt());
      }

      if (!_validStart(job, start.fileIndex, start.offset)) {
        await _sendQuietly(
          session,
          Cancel(transferId: job.id, reason: .FAILURE_REASON_PROTOCOL),
        );
        _fail(job, .protocol);
        return;
      }

      job.speed.reset();
      _set(
        job,
        (transfer) => transfer.copyWith(
          status: .transferring,
          clearFailure: true,
          bytesDone: job.bytesBefore(start.fileIndex) + start.offset,
          bytesPerSecond: 0,
        ),
      );

      for (var index = start.fileIndex; index < job.files.length; index++) {
        final from = switch (index == start.fileIndex) {
          true => start.offset,
          false => 0,
        };
        await _sendFile(session, job, index, from);
        if (job.cancelled) {
          return;
        }
      }

      await _whileOpen(
        session,
        session.send(featureId, TransferComplete(transferId: job.id)),
      );
      _set(
        job,
        (transfer) => transfer.copyWith(
          status: .done,
          bytesDone: transfer.totalBytes,
          bytesPerSecond: 0,
        ),
      );
      await _forget(job);
    } on _Stop {
      return;
    } on _SourceChanged {
      await _sendQuietly(
        session,
        Cancel(transferId: job.id, reason: .FAILURE_REASON_SOURCE_CHANGED),
      );
      _fail(job, .sourceChanged);
    } on FileSystemException catch (error) {
      printWarning('Drop could not read a file to send', error.osError);
      await _sendQuietly(
        session,
        Cancel(transferId: job.id, reason: .FAILURE_REASON_SOURCE_CHANGED),
      );
      _fail(job, .sourceChanged);
    } on TimeoutException {
      _fail(
        job,
        switch (registry[job.id]?.status) {
          TransferStatus.waiting => .timedOut,
          _ => .disconnected,
        },
      );
    } on SessionClosedException {
      _fail(job, .disconnected);
    } on StateError {
      _fail(job, .disconnected);
    } on IOException {
      // The socket gave up on a link that died without a word.
      _fail(job, .disconnected);
    } on RemoteErrorException catch (error) {
      _fail(
        job,
        switch (error.code) {
          .ERROR_CODE_UNSUPPORTED => .unsupported,
          .ERROR_CODE_CANCELLED => .cancelledByPeer,
          _ => .protocol,
        },
      );
    }
  }

  Future<void> _sendFile(
    Session session,
    OutgoingJob job,
    int index,
    int from,
  ) async {
    final file = job.files[index];
    final input = await File(file.path).open();
    final digest = DigestSink();
    final hash = sha256.startChunkedConversion(digest);
    final throttle = ProgressThrottle();
    final base = job.bytesBefore(index);

    try {
      if (await input.length() != file.size) {
        throw const _SourceChanged();
      }

      var position = 0;
      while (position < from) {
        final bytes = await input.read(min(chunkSize, from - position));
        if (bytes.isEmpty) {
          throw const _SourceChanged();
        }

        hash.add(bytes);
        position += bytes.length;
      }

      Future<Envelope>? pendingAck;
      var sent = 0;
      while (position < file.size) {
        if (job.cancelled) {
          throw const _Stop();
        }

        final bytes = await input.read(min(chunkSize, file.size - position));
        if (bytes.isEmpty) {
          throw const _SourceChanged();
        }

        hash.add(bytes);
        final chunk = Chunk(
          transferId: job.id,
          fileIndex: index,
          offset: Int64(position),
          data: bytes,
        );
        sent++;
        final window = await _sendChunk(
          session,
          chunk,
          wantsAck: sent % ackEvery == 0,
          previousAck: pendingAck,
        );
        pendingAck = window.ack;

        position += bytes.length;
        job.speed.add(base + position);
        if (throttle.shouldEmit) {
          _progress(job, base + position);
        }
      }

      await _whileOpen(session, pendingAck ?? Future.value());
      hash.close();
    } finally {
      await input.close();
    }

    if (job.cancelled) {
      throw const _Stop();
    }

    _set(
      job,
      (transfer) =>
          transfer.copyWith(status: .verifying, bytesDone: base + file.size),
    );
    final verified = await _whileOpen(
      session,
      session.call(
        featureId,
        FileComplete(
          transferId: job.id,
          fileIndex: index,
          sha256: digest.value.bytes,
        ),
        FileVerified.new,
        timeout: _verifyTimeout(file.size),
      ),
    );
    if (job.cancelled) {
      throw const _Stop();
    }

    if (!verified.ok) {
      _fail(job, FailureCodes.fromWire(verified.reason));
      throw const _Stop();
    }

    _set(job, (transfer) => transfer.copyWith(status: .transferring));
  }

  /// Sends [chunk]. A chunk that [wantsAck] goes as a request, but only
  /// after the previous one was answered, so at most two windows are in
  /// flight. Returns the acknowledgement to wait for next.
  Future<({Future<Envelope>? ack})> _sendChunk(
    Session session,
    Chunk chunk, {
    required bool wantsAck,
    required Future<Envelope>? previousAck,
  }) async {
    if (!wantsAck) {
      await _whileOpen(session, session.send(featureId, chunk));
      return (ack: previousAck);
    }

    await _whileOpen(session, previousAck ?? Future.value());
    final ack = session.request(featureId, chunk, timeout: ackTimeout)
      ..ignore();
    return (ack: ack);
  }

  /// [work], or [SessionClosedException] as soon as [session] closes. A
  /// write into a link that died without a word, such as Wi-Fi switched
  /// off, can hang until the socket gives up minutes later; the transfer
  /// should read as paused at once instead.
  Future<T> _whileOpen<T>(Session session, Future<T> work) {
    if (session.isClosed) {
      work.ignore();
      return Future.error(const SessionClosedException());
    }

    return Future.any([
      work,
      session.closed.then<T>((_) => throw const SessionClosedException()),
    ]);
  }

  TransferOffer _offerOf(OutgoingJob job) => TransferOffer(
    transferId: job.id,
    files: [
      for (final file in job.files)
        FileInfo(
          name: file.name,
          size: Int64(file.size),
          mime: file.mime,
          folder: file.folder,
          modifiedMs: switch (file.modified) {
            final modified? => Int64(modified.millisecondsSinceEpoch),
            null => null,
          },
        ),
    ],
    text: job.text,
    chunkSize: chunkSize,
  );

  bool _validStart(OutgoingJob job, int fileIndex, int offset) {
    if (fileIndex < 0 || fileIndex > job.files.length || offset < 0) {
      return false;
    }

    if (fileIndex == job.files.length) {
      return offset == 0;
    }

    return offset <= job.files[fileIndex].size;
  }

  /// Hashing on the receiver reads the file again, so big files get longer.
  Duration _verifyTimeout(int size) =>
      ackTimeout + Duration(seconds: size ~/ (20 * 1024 * 1024));

  void _progress(OutgoingJob job, int bytesDone) => _set(
    job,
    (transfer) => transfer.copyWith(
      bytesDone: bytesDone,
      bytesPerSecond: job.speed.bytesPerSecond,
    ),
  );

  void _fail(OutgoingJob job, TransferFailure failure) {
    final current = registry[job.id];
    if (current == null || !current.status.isActive) {
      return;
    }

    _set(
      job,
      (transfer) => transfer.copyWith(
        status: .failed,
        failure: failure,
        bytesPerSecond: 0,
      ),
    );
  }

  void _set(OutgoingJob job, Transfer Function(Transfer current) change) =>
      registry.update(job.id, change);

  Future<void> _forget(OutgoingJob job) async {
    _jobs.remove(job.id);
    if (!job.temporary) {
      return;
    }

    for (final file in job.files) {
      try {
        await File(file.path).delete();
      } on FileSystemException {
        continue;
      }
    }
  }

  Future<void> _sendQuietly(Session session, Cancel cancel) async {
    try {
      await session.send(featureId, cancel);
    } on Object {
      return;
    }
  }
}

class _Stop implements Exception {
  const _Stop();
}

class _SourceChanged implements Exception {
  const _SourceChanged();
}
