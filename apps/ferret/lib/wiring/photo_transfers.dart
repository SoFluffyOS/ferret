import 'dart:async';

import 'package:drop/drop.dart';
import 'package:engine/engine.dart';
import 'package:photos/photos.dart';

/// Carries full photos through drop's transfers (resume, SHA-256). Photos
/// and Drop never import each other, so the app joins them here.
class DropPhotoTransfers implements PhotoTransfers {
  DropPhotoTransfers(this._drop, {this.appearWithin = _appearWithin});

  static const _appearWithin = Duration(seconds: 60);

  final DropFeature _drop;

  /// How long a transfer the phone promised may take to show up here.
  final Duration appearWithin;

  /// Joins the engine's Photos and Drop features; does nothing when either
  /// is missing.
  static void attach(FerretEngine engine) {
    final photos = engine.feature<PhotosFeature>();
    final drop = engine.feature<DropFeature>();
    if (photos == null || drop == null) {
      return;
    }

    photos.transfers = DropPhotoTransfers(drop);
  }

  @override
  Future<String?> send(String deviceId, List<String> paths) async {
    final transfer = await _drop.sendFiles(deviceId, paths, temporary: true);
    return transfer?.id;
  }

  /// Accepts the transfer without asking (this computer asked for it), and
  /// takes its line out of the Files list once it ends: the photos line in
  /// Activity tells the story.
  @override
  Stream<PhotoTransferProgress> follow(String transferId) async* {
    final changes = StreamController<Transfer>();
    final subscription = _drop.updates
        .where((transfer) => transfer.id == transferId)
        .listen(changes.add);
    if (_drop.registry[transferId] case final current?) {
      changes.add(current);
    }

    try {
      final updates = changes.stream.timeout(
        appearWithin,
        onTimeout: (sink) => sink.close(),
      );
      await for (final transfer in updates) {
        if (transfer.needsAnswer) {
          _drop.answer(transferId, accept: true);
        }

        final progress = progressOf(transfer);
        yield progress;
        if (progress.status != .running) {
          _drop.dismiss(transferId);
          return;
        }
      }

      yield const PhotoTransferProgress(status: .failed);
    } finally {
      await subscription.cancel();
      await changes.close();
    }
  }

  /// [transfer] as photos sees it.
  static PhotoTransferProgress progressOf(Transfer transfer) {
    final total = transfer.totalBytes;
    final fraction = switch (total) {
      0 => 0.0,
      _ => (transfer.bytesDone / total).clamp(0.0, 1.0),
    };

    return switch (transfer.status) {
      .done => PhotoTransferProgress(
        status: .done,
        fraction: 1,
        paths: [
          for (final file in transfer.files) ?file.location,
        ],
      ),
      .failed || .cancelled => const PhotoTransferProgress(status: .failed),
      .waiting || .transferring || .verifying => PhotoTransferProgress(
        status: .running,
        fraction: fraction,
      ),
    };
  }
}
