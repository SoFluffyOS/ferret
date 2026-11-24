import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:drop/services/file_names.dart';
import 'package:drop/services/folder_paths.dart';
import 'package:drop/services/folder_plan.dart';
import 'package:drop/services/localsend/localsend_ids.dart';
import 'package:drop/services/progress_throttle.dart';
import 'package:drop/services/receive_store.dart';
import 'package:drop/services/speed_meter.dart';
import 'package:drop/services/transfer_ids.dart';
import 'package:drop/services/transfer_registry.dart';
import 'package:interop_localsend/interop_localsend.dart';
import 'package:path/path.dart' as p;

/// Receives from LocalSend devices into Drop: every offer waits for
/// someone here to accept it, then files go through the same
/// [ReceiveStore] and [TransferRegistry] as Ferret transfers.
class LocalSendReceiver implements LocalSendReceiveDelegate {
  LocalSendReceiver({
    required this.registry,
    required this.store,
    this.answerTimeout = const Duration(minutes: 2),
  });

  final TransferRegistry registry;
  final ReceiveStore store;

  /// How long an offer waits for an answer before it is declined.
  final Duration answerTimeout;

  /// Stops a session on the server, set by whoever runs it.
  Future<void> Function(String sessionId)? cancelSession;

  final Map<String, _Incoming> _sessions = {};
  final Map<String, Completer<bool>> _answers = {};

  /// Whether [transferId] is a LocalSend offer or transfer still running.
  bool owns(String transferId) =>
      _answers.containsKey(transferId) ||
      _sessions.values.any((incoming) => incoming.transferId == transferId);

  /// Accepts or declines an offer waiting for this device's answer.
  void answer(String transferId, {required bool accept}) =>
      _answers.remove(transferId)?.complete(accept);

  /// Declines a waiting offer, or stops a running transfer.
  Future<void> cancel(String transferId) async {
    if (_answers.containsKey(transferId)) {
      answer(transferId, accept: false);
      return;
    }

    final incoming = _find(transferId);
    if (incoming == null) {
      return;
    }

    _sessions.remove(incoming.sessionId);
    await cancelSession?.call(incoming.sessionId);
    await _discardParts(incoming);
    registry.update(
      transferId,
      (transfer) => transfer.copyWith(status: .cancelled, bytesPerSecond: 0),
    );
  }

  /// Receiving was turned off: declines what waits and stops what runs.
  Future<void> cancelAll() async {
    for (final transferId in [..._answers.keys]) {
      answer(transferId, accept: false);
    }

    for (final incoming in [..._sessions.values]) {
      await cancel(incoming.transferId);
    }
  }

  @override
  Future<Set<String>?> onOffer(LocalSendOffer offer) async {
    final transferId = TransferIds.next();
    final message = _messageOf(offer);
    final paths = [
      for (final file in offer.files) FolderPaths.split(file.fileName),
    ];
    final plan = FolderPlan.parse([for (final path in paths) path.folder]);
    if (plan == null) {
      printWarning('Drop refused a LocalSend offer with unsafe folders');
      return null;
    }

    final transfer = Transfer(
      id: transferId,
      direction: .incoming,
      deviceId: LocalSendIds.deviceId(offer.sender.fingerprint),
      deviceName: LocalSendIds.label(offer.sender.alias),
      files: switch (message) {
        null => [
          for (final (index, file) in offer.files.indexed)
            TransferFile(
              name: FileNames.safe(paths[index].name),
              size: file.size,
              mime: file.fileType,
              folder: plan.remote[index],
              modified: file.modified,
            ),
        ],
        _ => const [],
      },
      status: .waiting,
      startedAt: DateTime.now(),
      needsAnswer: true,
      localSend: LocalSendOrigin(
        deviceModel: offer.sender.deviceModel ?? '',
        fingerprint: offer.sender.fingerprint,
        address: offer.address.address,
      ),
    );
    final incoming = _Incoming(offer.sessionId, transferId);
    _sessions[offer.sessionId] = incoming;

    final accepted = await _ask(transfer);
    if (!accepted) {
      _sessions.remove(offer.sessionId);
      return null;
    }

    if (message != null) {
      _sessions.remove(offer.sessionId);
      registry.update(
        transferId,
        (current) =>
            current.copyWith(text: message, status: .done, needsAnswer: false),
      );
      return const {};
    }

    try {
      incoming
        ..parts = await store.partsDirectory()
        ..folders = await plan.place(store);
    } on Object catch (error) {
      printWarning(
        'Drop could not prepare the receive folder: ${error.runtimeType}',
      );
      _sessions.remove(offer.sessionId);
      registry.update(
        transferId,
        (current) => current.copyWith(
          status: .failed,
          failure: .storage,
          needsAnswer: false,
        ),
      );
      return null;
    }

    registry.update(
      transferId,
      (current) => current.copyWith(
        status: .transferring,
        needsAnswer: false,
        files: [
          for (final (index, file) in current.files.indexed)
            file.copyWith(folder: incoming.folders.elementAtOrNull(index)),
        ],
      ),
    );
    return {for (final file in offer.files) file.id};
  }

  @override
  Future<File> partFile(LocalSendOffer offer, LocalSendFile file) async {
    final incoming = _sessions[offer.sessionId];
    if (incoming == null || incoming.parts == null) {
      throw StateError('No LocalSend session to write to');
    }

    // Asks again, since a finished transfer may have tidied the folder away.
    final parts = incoming.parts = await store.partsDirectory();

    final index = offer.files.indexWhere((listed) => listed.id == file.id);
    return File(p.join(parts.path, '${incoming.transferId}-$index.part'));
  }

  @override
  void onProgress(LocalSendOffer offer, int receivedBytes) {
    final incoming = _sessions[offer.sessionId];
    if (incoming == null) {
      return;
    }

    incoming.speed.add(receivedBytes);
    if (!incoming.throttle.shouldEmit) {
      return;
    }

    registry.update(
      incoming.transferId,
      (transfer) => transfer.copyWith(
        bytesDone: receivedBytes,
        bytesPerSecond: incoming.speed.bytesPerSecond,
      ),
    );
  }

  @override
  Future<void> onFileReceived(
    LocalSendOffer offer,
    LocalSendFile file,
    File part,
  ) async {
    final incoming = _sessions[offer.sessionId];
    if (incoming == null) {
      throw StateError('No LocalSend session to save into');
    }

    final index = offer.files.indexWhere((listed) => listed.id == file.id);
    final saved = await store.save(
      part,
      name: FileNames.safe(FolderPaths.split(file.fileName).name),
      mime: file.fileType,
      folder: incoming.folders.elementAtOrNull(index),
      modified: file.modified,
    );
    registry.update(
      incoming.transferId,
      (transfer) => transfer.copyWith(
        files: [
          for (final (fileIndex, listed) in transfer.files.indexed)
            switch (fileIndex == index) {
              true => listed.copyWith(
                name: saved.name,
                location: saved.location,
              ),
              false => listed,
            },
        ],
      ),
    );
  }

  @override
  void onSessionEnded(LocalSendOffer offer, LocalSendSessionEnd end) {
    final incoming = _sessions.remove(offer.sessionId);
    if (incoming == null) {
      return;
    }

    final withdrawn = _answers.remove(incoming.transferId);
    registry.update(
      incoming.transferId,
      (transfer) => switch (end) {
        .finished => transfer.copyWith(
          status: .done,
          bytesDone: transfer.totalBytes,
          bytesPerSecond: 0,
        ),
        .cancelledBySender => transfer.copyWith(
          status: .cancelled,
          failure: .cancelledByPeer,
          bytesPerSecond: 0,
          needsAnswer: false,
        ),
        .stalled => transfer.copyWith(
          status: .failed,
          failure: .unreachable,
          bytesPerSecond: 0,
        ),
        .storageFailed => transfer.copyWith(
          status: .failed,
          failure: .storage,
          bytesPerSecond: 0,
        ),
      },
    );
    withdrawn?.complete(false);
    if (end != .finished) {
      unawaited(_discardParts(incoming));
    }
  }

  /// The text of [offer] when it is a text message and nothing else.
  String? _messageOf(LocalSendOffer offer) {
    if (offer.files case [final only] when only.isMessage) {
      return only.preview;
    }

    return null;
  }

  Future<bool> _ask(Transfer transfer) async {
    final pending = Completer<bool>();
    _answers[transfer.id] = pending;
    registry.put(transfer);

    final accepted = await pending.future.timeout(
      answerTimeout,
      onTimeout: () => false,
    );
    final timedOut = _answers.remove(transfer.id) != null;
    if (accepted) {
      return true;
    }

    registry.update(
      transfer.id,
      (current) => switch ((current.status, timedOut)) {
        (TransferStatus.waiting, true) => current.copyWith(
          status: .failed,
          failure: .timedOut,
          needsAnswer: false,
        ),
        (TransferStatus.waiting, false) => current.copyWith(
          status: .cancelled,
          failure: .declined,
          needsAnswer: false,
        ),
        _ => current,
      },
    );
    return false;
  }

  _Incoming? _find(String transferId) {
    for (final incoming in _sessions.values) {
      if (incoming.transferId == transferId) {
        return incoming;
      }
    }

    return null;
  }

  /// Deletes what is left of files that never finished.
  Future<void> _discardParts(_Incoming incoming) async {
    final parts = incoming.parts;
    if (parts == null) {
      return;
    }

    try {
      await for (final entity in parts.list()) {
        final name = p.basename(entity.path);
        if (name.startsWith('${incoming.transferId}-')) {
          await entity.delete();
        }
      }
    } on FileSystemException {
      return;
    }
  }
}

class _Incoming {
  _Incoming(this.sessionId, this.transferId);

  final String sessionId;
  final String transferId;
  final SpeedMeter speed = SpeedMeter();
  final ProgressThrottle throttle = ProgressThrottle();
  Directory? parts;

  /// The folder each file goes to here, null for loose files.
  List<String?> folders = const [];
}
