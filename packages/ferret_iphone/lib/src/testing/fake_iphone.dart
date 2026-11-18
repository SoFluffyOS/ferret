import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_iphone/src/ams/ams.dart';
import 'package:ferret_iphone/src/ancs/ancs.dart';
import 'package:ferret_iphone/src/testing/fake_apple_transport.dart';
import 'package:ferret_iphone/src/transport/transport.dart';

/// Plays an iPhone on a [FakeAppleTransport]: answers ANCS commands from the
/// notifications and apps it holds, and builds the packets a real one sends.
class FakeIphone {
  FakeIphone(this.transport, {this.packetSize = 180}) {
    transport.onWrite = _onWrite;
  }

  final FakeAppleTransport transport;

  /// Answers longer than this are split, as a real link splits them.
  int packetSize;

  /// The attributes of each notification, by uid.
  final Map<int, Map<AncsAttribute, String>> notifications = {};

  /// App display names by bundle id.
  final Map<String, String> apps = {};

  /// The actions the computer asked for, as (uid, action).
  final List<(int, AncsAction)> performed = [];

  /// The media commands the computer sent.
  final List<AmsCommand> commands = [];

  /// When true, commands get no answer.
  bool silent = false;

  /// A Notification Source packet.
  static Uint8List eventPacket(
    int uid, {
    AncsEventKind kind = .added,
    AncsCategory category = .other,
    bool silent = false,
    bool preExisting = false,
    bool positive = false,
    bool negative = false,
    int categoryCount = 1,
  }) {
    final flags =
        _bit(silent, 0) |
        _bit(preExisting, 2) |
        _bit(positive, 3) |
        _bit(negative, 4);
    final data = ByteData(8)
      ..setUint8(0, kind.index)
      ..setUint8(1, flags)
      ..setUint8(2, category.index)
      ..setUint8(3, categoryCount)
      ..setUint32(4, uid, Endian.little);

    return data.buffer.asUint8List();
  }

  /// A Data Source answer to Get Notification Attributes.
  static Uint8List attributesPacket(int uid, Map<int, String> attributes) {
    final builder = BytesBuilder()
      ..addByte(AncsCommands.getNotificationAttributes)
      ..add(
        (ByteData(4)..setUint32(0, uid, Endian.little)).buffer.asUint8List(),
      )
      ..add(_tuples(attributes));

    return builder.toBytes();
  }

  /// A Data Source answer to Get App Attributes.
  static Uint8List appPacket(String appId, Map<int, String> attributes) {
    final builder = BytesBuilder()
      ..addByte(AncsCommands.getAppAttributes)
      ..add(utf8.encode(appId))
      ..addByte(0)
      ..add(_tuples(attributes));

    return builder.toBytes();
  }

  /// An AMS Entity Update packet.
  static Uint8List updatePacket(
    AmsEntity entity,
    int attribute,
    String value, {
    bool truncated = false,
  }) => Uint8List.fromList([
    entity.index,
    attribute,
    _bit(truncated, 0),
    ...utf8.encode(value),
  ]);

  /// A notification arrives on the iPhone.
  void notify(
    int uid, {
    String appId = 'com.example.chat',
    String title = '',
    String subtitle = '',
    String message = '',
    String date = '',
    AncsEventKind kind = .added,
    AncsCategory category = .other,
    bool silent = false,
    bool preExisting = false,
    bool positive = false,
    bool negative = true,
  }) {
    notifications[uid] = {
      .appIdentifier: appId,
      .title: title,
      .subtitle: subtitle,
      .message: message,
      .date: date,
      .positiveActionLabel: switch (positive) {
        true => 'Answer',
        false => '',
      },
      .negativeActionLabel: switch (negative) {
        true => 'Clear',
        false => '',
      },
    };
    transport.emit(
      .notificationSource,
      eventPacket(
        uid,
        kind: kind,
        category: category,
        silent: silent,
        preExisting: preExisting,
        positive: positive,
        negative: negative,
      ),
    );
  }

  /// A notification goes away on the iPhone.
  void remove(int uid) {
    notifications.remove(uid);
    transport.emit(.notificationSource, eventPacket(uid, kind: .removed));
  }

  /// The player, queue or track changes.
  void update(AmsEntity entity, int attribute, String value) =>
      transport.emit(.entityUpdate, updatePacket(entity, attribute, value));

  /// A track starts playing in [player].
  void play({
    String player = 'Music',
    String title = 'Song',
    String artist = 'Artist',
    String album = 'Album',
    double duration = 200,
    double elapsed = 0,
  }) {
    update(.player, AmsPlayerAttribute.name, player);
    update(.track, AmsTrackAttribute.title, title);
    update(.track, AmsTrackAttribute.artist, artist);
    update(.track, AmsTrackAttribute.album, album);
    update(.track, AmsTrackAttribute.duration, '$duration');
    update(.player, AmsPlayerAttribute.playbackInfo, '1,1.0,$elapsed');
  }

  void _onWrite(AppleCharacteristic characteristic, Uint8List value) {
    if (characteristic == .remoteCommand && value.isNotEmpty) {
      if (AmsCommand.fromId(value.first) case final command?) {
        commands.add(command);
      }

      return;
    }

    if (characteristic != .controlPoint || value.isEmpty) {
      return;
    }

    switch (value.first) {
      case AncsCommands.getNotificationAttributes:
        _answerNotification(value);
      case AncsCommands.getAppAttributes:
        _answerApp(value);
      case AncsCommands.performNotificationAction:
        final uid = ByteData.sublistView(value).getUint32(1, Endian.little);
        performed.add((uid, AncsAction.values[value[5]]));
    }
  }

  void _answerNotification(Uint8List command) {
    final data = ByteData.sublistView(command);
    final uid = data.getUint32(1, Endian.little);
    final known = notifications[uid];
    if (known == null) {
      throw const GattException(.att, attError: AncsError.invalidParameter);
    }

    final attributes = <int, String>{};
    var offset = 5;
    while (offset < command.length) {
      final attribute = AncsAttribute.fromId(command[offset]);
      offset++;
      if (attribute == null) {
        continue;
      }

      var text = known[attribute] ?? '';
      if (attribute.needsMaxLength) {
        final maxLength = data.getUint16(offset, Endian.little);
        offset += 2;
        final encoded = utf8.encode(text);
        if (encoded.length > maxLength) {
          text = utf8.decode(
            encoded.sublist(0, maxLength),
            allowMalformed: true,
          );
        }
      }

      attributes[attribute.id] = text;
    }

    _send(attributesPacket(uid, attributes));
  }

  void _answerApp(Uint8List command) {
    final end = command.indexOf(0, 1);
    final appId = utf8.decode(command.sublist(1, end));
    final name = apps[appId];
    if (name == null) {
      throw const GattException(.att, attError: AncsError.invalidParameter);
    }

    _send(appPacket(appId, {AncsAppAttribute.displayName: name}));
  }

  void _send(Uint8List answer) {
    if (silent) {
      return;
    }

    for (var start = 0; start < answer.length; start += packetSize) {
      final end = (start + packetSize).clamp(0, answer.length);
      transport.emit(.dataSource, answer.sublist(start, end));
    }
  }

  static Uint8List _tuples(Map<int, String> attributes) {
    final builder = BytesBuilder();
    for (final MapEntry(key: id, value: text) in attributes.entries) {
      final encoded = utf8.encode(text);
      builder
        ..addByte(id)
        ..add(
          (ByteData(
            2,
          )..setUint16(0, encoded.length, Endian.little)).buffer.asUint8List(),
        )
        ..add(encoded);
    }

    return builder.toBytes();
  }

  static int _bit(bool on, int position) => switch (on) {
    true => 1 << position,
    false => 0,
  };
}
