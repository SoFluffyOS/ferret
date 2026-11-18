import 'dart:async';
import 'dart:io';

import 'package:interop_localsend/interop_localsend.dart';
import 'package:path/path.dart' as p;

/// A receive delegate that saves into [folder] and records what happened.
class RecordingDelegate implements LocalSendReceiveDelegate {
  RecordingDelegate(this.folder);

  final Directory folder;

  /// Decides each offer. Accepts everything by default.
  Future<Set<String>?> Function(LocalSendOffer offer) decide = (offer) async =>
      {
        for (final file in offer.files) file.id,
      };

  /// Set to make saving fail.
  bool failSaving = false;

  final List<LocalSendOffer> offers = [];
  final List<int> progress = [];
  final List<String> saved = [];
  final List<LocalSendSessionEnd> ends = [];
  final Completer<void> firstProgress = Completer();

  @override
  Future<Set<String>?> onOffer(LocalSendOffer offer) {
    offers.add(offer);
    return decide(offer);
  }

  @override
  Future<File> partFile(LocalSendOffer offer, LocalSendFile file) async =>
      File(p.join(folder.path, '${offer.sessionId}-${file.id}.part'));

  @override
  void onProgress(LocalSendOffer offer, int receivedBytes) {
    progress.add(receivedBytes);
    if (!firstProgress.isCompleted && receivedBytes > 0) {
      firstProgress.complete();
    }
  }

  @override
  Future<void> onFileReceived(
    LocalSendOffer offer,
    LocalSendFile file,
    File part,
  ) async {
    if (failSaving) {
      throw const FileSystemException('disk full');
    }

    await part.rename(p.join(folder.path, file.fileName));
    saved.add(file.fileName);
  }

  @override
  void onSessionEnded(LocalSendOffer offer, LocalSendSessionEnd end) =>
      ends.add(end);

  List<String> get partFiles => [
    for (final entity in folder.listSync())
      if (entity.path.endsWith('.part')) p.basename(entity.path),
  ];
}
