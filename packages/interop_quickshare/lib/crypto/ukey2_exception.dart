import 'dart:typed_data';

import 'package:interop_quickshare/proto/proto.dart';

/// The UKEY2 handshake failed. When [alert] is set, the protocol asks to
/// tell the other side before closing.
class Ukey2Exception implements Exception {
  const Ukey2Exception(this.message, {this.alert});

  final String message;
  final Ukey2Alert_AlertType? alert;

  /// The alert as a frame to send, or null when the protocol says to
  /// close without a word.
  Uint8List? get alertFrame {
    final type = alert;
    if (type == null) {
      return null;
    }

    return Ukey2Message(
      messageType: Ukey2Message_Type.ALERT,
      messageData: Ukey2Alert(type: type).writeToBuffer(),
    ).writeToBuffer();
  }

  @override
  String toString() => 'Ukey2Exception: $message';
}
