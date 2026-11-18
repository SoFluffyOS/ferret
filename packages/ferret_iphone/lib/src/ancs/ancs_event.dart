import 'dart:typed_data';

/// What happened to a notification on the iPhone.
enum AncsEventKind { added, modified, removed }

/// The kind of notification, as iOS sorts them.
enum AncsCategory {
  other,
  incomingCall,
  missedCall,
  voicemail,
  social,
  schedule,
  email,
  news,
  healthAndFitness,
  businessAndFinance,
  location,
  entertainment;

  static AncsCategory fromId(int id) {
    if (id < 0 || id >= values.length) {
      return other;
    }

    return values[id];
  }
}

/// One packet from the Notification Source characteristic: 8 bytes that say
/// a notification arrived, changed or went away. The text comes later, by
/// asking for the attributes of [uid].
class AncsEvent {
  const AncsEvent({
    required this.kind,
    required this.flags,
    required this.category,
    required this.categoryCount,
    required this.uid,
  });

  static const length = 8;

  static const _silent = 1 << 0;
  static const _important = 1 << 1;
  static const _preExisting = 1 << 2;
  static const _positiveAction = 1 << 3;
  static const _negativeAction = 1 << 4;

  final AncsEventKind kind;

  /// The raw EventFlags bitmask.
  final int flags;
  final AncsCategory category;

  /// How many notifications of [category] are active on the iPhone.
  final int categoryCount;

  /// The iPhone's handle for the notification, valid for this connection.
  final int uid;

  bool get isSilent => flags & _silent != 0;

  bool get isImportant => flags & _important != 0;

  /// It was already on the iPhone before this computer connected.
  bool get isPreExisting => flags & _preExisting != 0;

  /// It has a positive action, such as answering a call.
  bool get hasPositiveAction => flags & _positiveAction != 0;

  /// It has a negative action, such as clearing it or declining a call.
  bool get hasNegativeAction => flags & _negativeAction != 0;

  /// Reads a Notification Source packet, or null when it is malformed.
  static AncsEvent? parse(Uint8List bytes) {
    if (bytes.length < length || bytes[0] >= AncsEventKind.values.length) {
      return null;
    }

    final data = ByteData.sublistView(bytes);

    return AncsEvent(
      kind: AncsEventKind.values[bytes[0]],
      flags: bytes[1],
      category: AncsCategory.fromId(bytes[2]),
      categoryCount: bytes[3],
      uid: data.getUint32(4, Endian.little),
    );
  }
}
