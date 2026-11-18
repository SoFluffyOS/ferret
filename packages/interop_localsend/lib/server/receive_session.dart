import 'dart:async';

import 'package:interop_localsend/server/localsend_offer.dart';

/// What the server keeps about the one session it is busy with.
class ReceiveSession {
  ReceiveSession(this.offer);

  final LocalSendOffer offer;

  /// Tokens by file id, once the offer was accepted.
  final Map<String, String> tokens = {};
  final Set<String> saved = {};
  final Map<String, int> received = {};

  /// Uploads being read right now, by file id.
  final Map<String, StreamIterator<List<int>>> uploads = {};

  /// Still waiting for someone here to accept.
  bool isPending = true;
  bool isEnded = false;
  DateTime lastActivity = DateTime.now();

  int get receivedBytes => received.values.fold(0, (sum, bytes) => sum + bytes);

  bool get isComplete => saved.length == tokens.length;

  /// Stops every upload being read.
  Future<void> abortUploads() async {
    for (final upload in [...uploads.values]) {
      await upload.cancel();
    }
  }
}
