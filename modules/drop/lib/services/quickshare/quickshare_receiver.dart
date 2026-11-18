import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drop/models/models.dart';
import 'package:drop/services/file_names.dart';
import 'package:drop/services/progress_throttle.dart';
import 'package:drop/services/quickshare/quickshare_ids.dart';
import 'package:drop/services/receive_store.dart';
import 'package:drop/services/speed_meter.dart';
import 'package:drop/services/transfer_ids.dart';
import 'package:drop/services/transfer_registry.dart';
import 'package:interop_quickshare/interop_quickshare.dart';
import 'package:path/path.dart' as p;

/// Receives from Quick Share senders into Drop: every offer waits for
/// someone here to accept it, with the PIN to compare, then files go
/// through the same [ReceiveStore] and [TransferRegistry] as Ferret
/// transfers.
class QuickShareReceiver implements QuickShareReceiveDelegate {
  QuickShareReceiver({
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

  /// Whether [transferId] is a Quick Share offer or transfer still
  /// running.
  bool owns(String transferId) =>
      _answers.containsKey(transferId) || _find(transferId) != null;

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

  /// Visibility was turned off: declines what waits and stops what runs.
  Future<void> cancelAll() async {
    for (final transferId in [..._answers.keys]) {
      answer(transferId, accept: false);
    }

    for (final incoming in [..._sessions.values]) {
      await cancel(incoming.transferId);
    }
  }

  @override
  Future<bool> onOffer(QuickShareOffer offer) async {
    final transferId = TransferIds.next();
    final transfer = Transfer(
      id: transferId,
      direction: .incoming,
      deviceId: QuickShareIds.deviceId(offer.sessionId),
      deviceName: QuickShareIds.label(offer.senderName),
      files: [
        for (final file in offer.files)
          TransferFile(
            name: FileNames.safe(file.name),
            size: file.size,
            mime: file.mimeType,
          ),
      ],
      status: .waiting,
      startedAt: DateTime.now(),
      needsAnswer: true,
      quickShare: QuickShareOrigin(
        pin: offer.pin,
        address: offer.address.address,
      ),
    );
    final incoming = _Incoming(offer.sessionId, transferId);
    _sessions[offer.sessionId] = incoming;

    final accepted = await _ask(transfer);
    if (!accepted) {
      _sessions.remove(offer.sessionId);
      return false;
    }

    if (offer.files.isEmpty) {
      registry.update(
        transferId,
        (current) => current.copyWith(needsAnswer: false),
      );
      return true;
    }

    try {
      incoming.parts = await store.partsDirectory();
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
      return false;
    }

    registry.update(
      transferId,
      (current) => current.copyWith(status: .transferring, needsAnswer: false),
    );
    return true;
  }

  @override
  Future<File> partFile(QuickShareOffer offer, QuickShareFile file) async {
    final incoming = _sessions[offer.sessionId];
    final parts = incoming?.parts;
    if (incoming == null || parts == null) {
      throw StateError('No Quick Share session to write to');
    }

    final index = offer.files.indexOf(file);
    return File(p.join(parts.path, '${incoming.transferId}-$index.part'));
  }

  @override
  void onProgress(QuickShareOffer offer, int receivedBytes) {
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
    QuickShareOffer offer,
    QuickShareFile file,
    File part,
  ) async {
    final incoming = _sessions[offer.sessionId];
    if (incoming == null) {
      throw StateError('No Quick Share session to save into');
    }

    final index = offer.files.indexOf(file);
    final saved = await store.save(
      part,
      name: FileNames.safe(file.name),
      mime: file.mimeType,
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
  void onTextReceived(
    QuickShareOffer offer,
    QuickShareText text,
    String content,
  ) {
    final incoming = _sessions[offer.sessionId];
    if (incoming == null) {
      return;
    }

    if (offer.files.isEmpty) {
      incoming.texts.add(content);
      registry.update(
        incoming.transferId,
        (transfer) => transfer.copyWith(text: incoming.texts.join('\n')),
      );
      return;
    }

    // A text that comes along with files gets its own entry, so neither
    // hides the other.
    final files = registry[incoming.transferId];
    registry.put(
      Transfer(
        id: TransferIds.next(),
        direction: .incoming,
        deviceId: QuickShareIds.deviceId(offer.sessionId),
        deviceName: QuickShareIds.label(offer.senderName),
        files: const [],
        text: content,
        status: .done,
        startedAt: DateTime.now(),
        quickShare: files?.quickShare,
      ),
    );
  }

  @override
  void onSessionEnded(QuickShareOffer offer, QuickShareSessionEnd end) {
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
        .connectionLost || .incomplete => transfer.copyWith(
          status: .failed,
          failure: .connectionLost,
          bytesPerSecond: 0,
          needsAnswer: false,
        ),
        .storageFailed => transfer.copyWith(
          status: .failed,
          failure: .storage,
          bytesPerSecond: 0,
        ),
        .protocolError => transfer.copyWith(
          status: .failed,
          failure: .protocol,
          bytesPerSecond: 0,
          needsAnswer: false,
        ),
      },
    );
    withdrawn?.complete(false);
    if (end != .finished) {
      unawaited(_discardParts(incoming));
    }
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
  final List<String> texts = [];
  Directory? parts;
}
