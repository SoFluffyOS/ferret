import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drop/models/models.dart';
import 'package:drop/services/localsend/localsend_ids.dart';
import 'package:drop/services/localsend/localsend_outgoing_job.dart';
import 'package:drop/services/outgoing_file.dart';
import 'package:drop/services/transfer_ids.dart';
import 'package:drop/services/transfer_registry.dart';
import 'package:interop_localsend/interop_localsend.dart';

/// Sends files and text to LocalSend devices, reporting to the same
/// [TransferRegistry] as Ferret transfers.
class LocalSendSender {
  LocalSendSender({
    required this.registry,
    required this.client,
    required this.self,
  });

  final TransferRegistry registry;

  /// The HTTP client, ready once this device has its certificate.
  final Future<LocalSendClient> Function() client;

  /// How this device describes itself to the receiver.
  final Future<LocalSendInfo> Function() self;

  final Map<String, LocalSendOutgoingJob> _jobs = {};

  bool owns(String id) => _jobs.containsKey(id);

  Transfer sendFiles(
    LocalSendPeer peer,
    List<OutgoingFile> files, {
    bool temporary = false,
  }) => _start(
    LocalSendOutgoingJob(
      id: TransferIds.next(),
      peer: peer,
      files: files,
      temporary: temporary,
    ),
  );

  Transfer sendText(LocalSendPeer peer, String text) => _start(
    LocalSendOutgoingJob(
      id: TransferIds.next(),
      peer: peer,
      files: const [],
      text: text,
    ),
  );

  /// Offers the transfer again, with [pin] when the receiver asked for
  /// one.
  Future<void> retry(String id, {String? pin}) async {
    final job = _jobs[id];
    if (job == null || job.running != null) {
      return;
    }

    job
      ..cancelled = false
      ..speed.reset();
    registry.update(
      id,
      (transfer) => transfer.copyWith(
        status: .waiting,
        clearFailure: true,
        bytesDone: 0,
        bytesPerSecond: 0,
      ),
    );
    unawaited(_run(job, pin: pin));
  }

  Future<void> cancel(String id) async {
    final job = _jobs.remove(id);
    if (job == null) {
      return;
    }

    job.cancelled = true;
    registry.update(
      id,
      (transfer) => transfer.copyWith(status: .cancelled, bytesPerSecond: 0),
    );
    await job.running?.cancel();
    await _deleteTemporary(job);
  }

  /// Stops everything, such as when the app closes.
  Future<void> dispose() async {
    for (final id in [..._jobs.keys]) {
      await cancel(id);
    }
  }

  Transfer _start(LocalSendOutgoingJob job) {
    final transfer = Transfer(
      id: job.id,
      direction: .outgoing,
      deviceId: LocalSendIds.deviceId(job.peer.fingerprint),
      deviceName: LocalSendIds.label(job.peer.info.alias),
      files: [
        for (final file in job.files)
          TransferFile(
            name: file.name,
            size: file.size,
            mime: file.mime,
            location: file.path,
          ),
      ],
      text: job.text,
      status: .waiting,
      startedAt: DateTime.now(),
      localSend: LocalSendOrigin(
        deviceModel: job.peer.info.deviceModel ?? '',
        fingerprint: job.peer.fingerprint,
        address: job.peer.address.address,
      ),
    );
    _jobs[job.id] = job;
    registry.put(transfer);
    unawaited(_run(job));
    return transfer;
  }

  Future<void> _run(LocalSendOutgoingJob job, {String? pin}) async {
    try {
      final sending = LocalSendSendJob(
        client: await client(),
        peer: job.peer,
        self: await self(),
        files: _describe(job),
        pin: pin,
      );
      job.running = sending;
      if (job.cancelled) {
        return;
      }

      await sending.run(
        onAccepted: () => _set(
          job,
          (transfer) => transfer.copyWith(status: .transferring),
        ),
        onProgress: (sentBytes) => _progress(job, sentBytes),
      );
      _set(
        job,
        (transfer) => transfer.copyWith(
          status: .done,
          bytesDone: transfer.totalBytes,
          bytesPerSecond: 0,
        ),
      );
      _jobs.remove(job.id);
      await _deleteTemporary(job);
    } on LocalSendException catch (error) {
      _fail(job, _failureOf(error.failure));
    } on FileSystemException {
      _fail(job, .sourceChanged);
    } on Object {
      _fail(job, .protocol);
    } finally {
      job.running = null;
    }
  }

  List<LocalSendOutgoingFile> _describe(LocalSendOutgoingJob job) {
    if (job.text case final text?) {
      final bytes = utf8.encode(text);
      return [
        LocalSendOutgoingFile(
          file: LocalSendFile(
            id: job.id,
            fileName: '${job.id}.txt',
            size: bytes.length,
            fileType: 'text/plain',
            preview: text,
          ),
          open: () => Stream.value(bytes),
        ),
      ];
    }

    return [
      for (final (index, file) in job.files.indexed)
        LocalSendOutgoingFile(
          file: LocalSendFile(
            id: '${job.id}-$index',
            fileName: file.name,
            size: file.size,
            fileType: switch (file.mime.isEmpty) {
              true => LocalSendFile.defaultType,
              false => file.mime,
            },
          ),
          open: () => File(file.path).openRead(),
        ),
    ];
  }

  void _progress(LocalSendOutgoingJob job, int sentBytes) {
    job.speed.add(sentBytes);
    if (!job.throttle.shouldEmit) {
      return;
    }

    _set(
      job,
      (transfer) => transfer.copyWith(
        bytesDone: sentBytes,
        bytesPerSecond: job.speed.bytesPerSecond,
      ),
    );
  }

  void _fail(LocalSendOutgoingJob job, TransferFailure? failure) {
    if (job.cancelled || failure == null) {
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

  /// What to tell the person, or null when this side cancelled.
  TransferFailure? _failureOf(LocalSendFailure failure) => switch (failure) {
    .rejected => .declined,
    .pinRequired => .pinRequired,
    .tooManyRequests => .tooManyAttempts,
    .busy => .busy,
    .checksum => .checksum,
    .unreachable => .unreachable,
    .untrusted => .untrusted,
    .cancelled => null,
    .invalidRequest || .receiverError || .unexpected => .protocol,
  };

  void _set(
    LocalSendOutgoingJob job,
    Transfer Function(Transfer current) change,
  ) {
    if (job.cancelled) {
      return;
    }

    registry.update(job.id, change);
  }

  Future<void> _deleteTemporary(LocalSendOutgoingJob job) async {
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
}
