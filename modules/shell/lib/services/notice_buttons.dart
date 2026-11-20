import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// [action] as an Android notification button. One that opens the app
/// starts its activity; any other reaches the running app in the
/// background, so the phone stays locked and the person stays where they
/// were.
AndroidNotificationAction androidButton(NoticeAction action) =>
    AndroidNotificationAction(
      action.id,
      action.label,
      showsUserInterface: action.opensApp,
      inputs: switch (action.isReply) {
        true => [AndroidNotificationActionInput(label: action.label)],
        false => const [],
      },
    );

/// [action] as an iPhone or Mac notification button, with the same choice
/// of opening the app as on Android.
DarwinNotificationAction darwinButton(NoticeAction action) {
  final options = <DarwinNotificationActionOption>{
    if (action.opensApp) .foreground,
  };

  return switch (action.isReply) {
    true => DarwinNotificationAction.text(
      action.id,
      action.label,
      buttonTitle: action.label,
      placeholder: action.label,
      options: options,
    ),
    false => DarwinNotificationAction.plain(
      action.id,
      action.label,
      options: options,
    ),
  };
}

/// Who may read [notice] on Android. Android hides a private notice on a
/// locked phone and, since Android 15, while the screen is shared; null
/// leaves it to the channel, which is private.
NotificationVisibility? androidVisibility(LocalNotice notice) =>
    switch (notice.public && notice.private == null) {
      true => NotificationVisibility.public,
      false => null,
    };
