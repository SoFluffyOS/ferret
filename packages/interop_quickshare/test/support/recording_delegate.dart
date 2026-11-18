import 'dart:async';
import 'dart:io';

import 'package:interop_quickshare/interop_quickshare.dart';
import 'package:path/path.dart' as p;

/// A delegate that writes into [directory] and remembers what happened.
class RecordingDelegate implements QuickShareReceiveDelegate {
  RecordingDelegate(this.directory, {this.answer});

  final Directory directory;

  /// Decides about each offer. Accepts everything when null.
  Future<bool> Function(QuickShareOffer offer)? answer;

  final List<QuickShareOffer> offers = [];
  final Map<String, File> saved = {};
  final List<String> texts = [];
  final List<QuickShareSessionEnd> ends = [];
  int receivedBytes = 0;
  bool failSaving = false;

  @override
  Future<bool> onOffer(QuickShareOffer offer) async {
    offers.add(offer);
    return await answer?.call(offer) ?? true;
  }

  @override
  Future<File> partFile(QuickShareOffer offer, QuickShareFile file) async =>
      File(p.join(directory.path, '${file.payloadId}.part'));

  @override
  void onProgress(QuickShareOffer offer, int receivedBytes) =>
      this.receivedBytes = receivedBytes;

  @override
  Future<void> onFileReceived(
    QuickShareOffer offer,
    QuickShareFile file,
    File part,
  ) async {
    if (failSaving) {
      throw const FileSystemException('Disk full');
    }

    saved[file.name] = await part.rename(
      p.join(directory.path, p.basename(file.name)),
    );
  }

  @override
  void onTextReceived(
    QuickShareOffer offer,
    QuickShareText text,
    String content,
  ) => texts.add(content);

  @override
  void onSessionEnded(QuickShareOffer offer, QuickShareSessionEnd end) =>
      ends.add(end);
}
