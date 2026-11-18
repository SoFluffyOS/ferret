import 'dart:io';

import 'package:interop_quickshare/models/models.dart';

/// What a Quick Share sender wants to give this device.
class QuickShareOffer {
  const QuickShareOffer({
    required this.sessionId,
    required this.senderName,
    required this.senderKind,
    required this.pin,
    required this.address,
    this.files = const [],
    this.texts = const [],
  });

  final String sessionId;

  /// The name the sender gave itself. Not verified: compare [pin] with
  /// the sender's screen to know who is on the other end.
  final String senderName;
  final QuickShareDeviceKind senderKind;

  /// The 4-digit PIN the sender's screen shows for this connection.
  final String pin;

  /// Where the offer came from.
  final InternetAddress address;
  final List<QuickShareFile> files;
  final List<QuickShareText> texts;

  int get totalBytes => files.fold(0, (sum, file) => sum + file.size);
}
