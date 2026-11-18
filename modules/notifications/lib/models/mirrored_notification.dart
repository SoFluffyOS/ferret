import 'dart:typed_data';

/// A button of a mirrored notification.
class MirroredAction {
  const MirroredAction({
    required this.id,
    required this.title,
    required this.isReply,
  });

  final String id;
  final String title;
  final bool isReply;
}

/// A notification from another device, shown on this one.
class MirroredNotification {
  const MirroredNotification({
    required this.deviceId,
    required this.key,
    required this.appPackage,
    required this.appName,
    required this.title,
    required this.text,
    required this.postedAt,
    required this.isConversation,
    this.actions = const [],
    this.appIcon,
  });

  final String deviceId;

  /// The source device's key for it.
  final String key;
  final String appPackage;
  final String appName;
  final String title;
  final String text;
  final DateTime postedAt;
  final bool isConversation;
  final List<MirroredAction> actions;
  final Uint8List? appIcon;

  /// The first action that takes typed text, if any.
  MirroredAction? get replyAction {
    for (final action in actions) {
      if (action.isReply) {
        return action;
      }
    }

    return null;
  }

  bool get canReply => replyAction != null;

  /// The line to show as the heading: the title, or the app when it has none.
  String get heading => switch (title.isEmpty) {
    true => appName,
    false => title,
  };
}
