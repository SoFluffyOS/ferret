import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_iphone/src/ams/ams_ids.dart';

/// One Entity Update notification: an attribute of the player, the queue or
/// the track got a new value.
class AmsUpdate {
  const AmsUpdate({
    required this.entity,
    required this.attribute,
    required this.value,
    this.isTruncated = false,
  });

  static const _truncatedFlag = 1 << 0;

  final AmsEntity entity;

  /// An id from [AmsPlayerAttribute], [AmsQueueAttribute] or
  /// [AmsTrackAttribute], depending on [entity].
  final int attribute;
  final String value;

  /// The value didn't fit the packet; the rest can be read from the Entity
  /// Attribute characteristic.
  final bool isTruncated;

  /// Reads an Entity Update packet (entity, attribute, flags, then UTF-8
  /// text), or null when it is malformed.
  static AmsUpdate? parse(Uint8List bytes) {
    if (bytes.length < 3 || bytes[0] >= AmsEntity.values.length) {
      return null;
    }

    return AmsUpdate(
      entity: AmsEntity.values[bytes[0]],
      attribute: bytes[1],
      isTruncated: bytes[2] & _truncatedFlag != 0,
      value: utf8.decode(Uint8List.sublistView(bytes, 3), allowMalformed: true),
    );
  }
}
