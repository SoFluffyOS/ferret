import 'dart:io';

import 'package:interop_localsend/models/models.dart';

/// What another LocalSend member wants to send to this device.
class LocalSendOffer {
  const LocalSendOffer({
    required this.sessionId,
    required this.sender,
    required this.address,
    required this.files,
  });

  final String sessionId;

  /// How the sender describes itself. Nothing in it is verified: anyone on
  /// the network can pick any alias and fingerprint.
  final LocalSendInfo sender;

  /// Where the offer came from.
  final InternetAddress address;
  final List<LocalSendFile> files;

  int get totalBytes => files.fold(0, (sum, file) => sum + file.size);
}
