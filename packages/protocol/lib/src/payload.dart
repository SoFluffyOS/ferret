import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';

/// Packs and unpacks feature payloads carried in an `Envelope`.
extension PayloadMessage on GeneratedMessage {
  /// The full protobuf name an `Envelope.type` carries for this message.
  String get payloadType => info_.qualifiedMessageName;

  Uint8List toPayload() => writeToBuffer();
}

/// Decodes a payload into a message of type [T], or null when [type] names a
/// different message.
T? unpackPayload<T extends GeneratedMessage>({
  required String type,
  required List<int> payload,
  required T Function() create,
}) {
  final message = create();
  if (message.info_.qualifiedMessageName != type) {
    return null;
  }

  return message..mergeFromBuffer(payload);
}
