import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_iphone/src/ancs/ancs_commands.dart';

/// Puts one Data Source answer back together. The iPhone splits an answer
/// over several packets when it doesn't fit one, and nothing marks the last:
/// the answer is complete when it holds as many attributes as were asked for.
class AncsResponseAssembler {
  /// For a Get Notification Attributes command about [uid].
  AncsResponseAssembler.notification(int uid, {required this.attributeCount})
    : _header = Uint8List.fromList([
        AncsCommands.getNotificationAttributes,
        ...(ByteData(4)..setUint32(0, uid, Endian.little)).buffer.asUint8List(),
      ]);

  /// For a Get App Attributes command about [appId].
  AncsResponseAssembler.app(String appId, {required this.attributeCount})
    : _header = Uint8List.fromList([
        AncsCommands.getAppAttributes,
        ...utf8.encode(appId),
        0,
      ]);

  /// How many attributes the command asked for.
  final int attributeCount;

  final Uint8List _header;
  final BytesBuilder _buffer = BytesBuilder();

  /// Adds one packet. Returns the attributes by id once the answer is
  /// complete, or null while more packets are needed. A packet that can't
  /// belong to this answer (left over from an earlier command) is dropped.
  Map<int, String>? add(Uint8List packet) {
    _buffer.add(packet);
    final bytes = _buffer.toBytes();
    if (!_matchesHeader(bytes)) {
      _buffer.clear();
      return null;
    }

    if (bytes.length < _header.length) {
      return null;
    }

    return _parse(bytes);
  }

  /// Even a first packet shorter than the header must agree with it.
  bool _matchesHeader(Uint8List bytes) {
    for (var index = 0; index < _header.length; index++) {
      if (index < bytes.length && bytes[index] != _header[index]) {
        return false;
      }
    }

    return true;
  }

  Map<int, String>? _parse(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final attributes = <int, String>{};
    var offset = _header.length;
    while (attributes.length < attributeCount) {
      if (offset + 3 > bytes.length) {
        return null;
      }

      final id = bytes[offset];
      final length = data.getUint16(offset + 1, Endian.little);
      final end = offset + 3 + length;
      if (end > bytes.length) {
        return null;
      }

      attributes[id] = utf8.decode(
        Uint8List.sublistView(bytes, offset + 3, end),
        allowMalformed: true,
      );
      offset = end;
    }

    return attributes;
  }
}
