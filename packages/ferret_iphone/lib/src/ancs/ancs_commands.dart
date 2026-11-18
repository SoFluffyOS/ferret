import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_iphone/src/ancs/ancs_attribute.dart';

/// Builds the commands written to the ANCS Control Point.
abstract final class AncsCommands {
  static const getNotificationAttributes = 0;
  static const getAppAttributes = 1;
  static const performNotificationAction = 2;

  /// Asks for [attributes] of notification [uid]. Text attributes are cut to
  /// [maxLength] bytes by the iPhone.
  static Uint8List notificationAttributes(
    int uid,
    List<AncsAttribute> attributes, {
    int maxLength = 256,
  }) {
    final builder = BytesBuilder()
      ..addByte(getNotificationAttributes)
      ..add(_uint32(uid));
    for (final attribute in attributes) {
      builder.addByte(attribute.id);
      if (attribute.needsMaxLength) {
        builder.add(_uint16(maxLength));
      }
    }

    return builder.toBytes();
  }

  /// Asks for the display name of the app with bundle id [appId].
  static Uint8List appAttributes(String appId) {
    final builder = BytesBuilder()
      ..addByte(getAppAttributes)
      ..add(utf8.encode(appId))
      ..addByte(0)
      ..addByte(AncsAppAttribute.displayName);

    return builder.toBytes();
  }

  static Uint8List performAction(int uid, AncsAction action) {
    final builder = BytesBuilder()
      ..addByte(performNotificationAction)
      ..add(_uint32(uid))
      ..addByte(action.id);

    return builder.toBytes();
  }

  static Uint8List _uint32(int value) =>
      (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();

  static Uint8List _uint16(int value) =>
      (ByteData(2)..setUint16(0, value, Endian.little)).buffer.asUint8List();
}
