/// What can be asked about a notification (NotificationAttributeID).
enum AncsAttribute {
  appIdentifier(0),
  title(1, needsMaxLength: true),
  subtitle(2, needsMaxLength: true),
  message(3, needsMaxLength: true),
  messageSize(4),
  date(5),
  positiveActionLabel(6),
  negativeActionLabel(7);

  const AncsAttribute(this.id, {this.needsMaxLength = false});

  final int id;

  /// The request must say how many bytes it wants at most.
  final bool needsMaxLength;

  static AncsAttribute? fromId(int id) {
    for (final attribute in values) {
      if (attribute.id == id) {
        return attribute;
      }
    }

    return null;
  }
}

/// What can be asked about an app (AppAttributeID).
abstract final class AncsAppAttribute {
  static const displayName = 0;
}

/// The two things a notification can be asked to do (ActionID).
enum AncsAction {
  /// Such as answering a call.
  positive(0),

  /// Such as clearing the notification or declining a call.
  negative(1);

  const AncsAction(this.id);

  final int id;
}

/// ATT error codes ANCS answers a Control Point write with.
abstract final class AncsError {
  static const unknownCommand = 0xA0;
  static const invalidCommand = 0xA1;

  /// Such as a notification that is already gone.
  static const invalidParameter = 0xA2;
  static const actionFailed = 0xA3;
}
