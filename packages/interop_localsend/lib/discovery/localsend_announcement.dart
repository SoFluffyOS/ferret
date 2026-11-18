import 'dart:convert';
import 'dart:typed_data';

import 'package:interop_localsend/models/models.dart';

/// A multicast discovery packet: a member's description, and whether it
/// asks the others to answer.
class LocalSendAnnouncement {
  const LocalSendAnnouncement({required this.info, required this.announce});

  /// Larger packets are ignored; real ones are a few hundred bytes.
  static const maxBytes = 4096;

  final LocalSendInfo info;

  /// True for "I'm here, who else?", false for an answer to one.
  final bool announce;

  /// Reads a packet, or returns null when it isn't a LocalSend
  /// announcement.
  static LocalSendAnnouncement? decode(List<int> packet) {
    if (packet.isEmpty || packet.length > maxBytes) {
      return null;
    }

    final Object? json;
    try {
      json = jsonDecode(utf8.decode(packet));
    } on FormatException {
      return null;
    }

    final info = LocalSendInfo.fromJson(json);
    if (info == null || json is! Map<String, dynamic>) {
      return null;
    }

    return LocalSendAnnouncement(
      info: info,
      announce: json['announce'] == true,
    );
  }

  Uint8List encode() =>
      utf8.encode(jsonEncode({...info.toJson(), 'announce': announce}));
}
