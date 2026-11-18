import 'package:ferret_iphone/ferret_iphone.dart';

/// A notification from the iPhone, ready to show on this computer.
class IphoneNotification {
  const IphoneNotification({
    required this.uid,
    required this.appId,
    required this.appName,
    this.title = '',
    this.subtitle = '',
    this.message = '',
    this.date,
    this.category = .other,
    this.isSilent = false,
    this.isUpdate = false,
    this.hasPositiveAction = false,
    this.hasNegativeAction = false,
  });

  /// The iPhone's handle for it, valid until the link drops.
  final int uid;
  final String appId;

  /// The app's name as the iPhone shows it, such as "Messages".
  final String appName;
  final String title;
  final String subtitle;
  final String message;
  final DateTime? date;
  final AncsCategory category;

  /// The iPhone showed it quietly.
  final bool isSilent;

  /// It replaces one that is already shown here.
  final bool isUpdate;

  /// Such as answering a call.
  final bool hasPositiveAction;

  /// Such as clearing it or declining a call.
  final bool hasNegativeAction;
}

/// What the notification feed tells the app.
sealed class FeedEvent {
  const FeedEvent();
}

/// A notification arrived or changed.
class FeedShown extends FeedEvent {
  const FeedShown(this.notification);

  final IphoneNotification notification;
}

/// A notification went away on the iPhone.
class FeedRemoved extends FeedEvent {
  const FeedRemoved(this.uid);

  final int uid;
}
