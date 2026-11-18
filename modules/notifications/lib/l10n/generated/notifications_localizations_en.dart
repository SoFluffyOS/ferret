// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'notifications_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class NotificationsLocalizationsEn extends NotificationsLocalizations {
  NotificationsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Notifications';

  @override
  String get explainer =>
      'Shows your phone\'s notifications on your computer. You pick which apps.';

  @override
  String get offerDescription =>
      'See your phone\'s notifications on your computer.';

  @override
  String get explainerDetail =>
      'Only new notifications from the apps you pick. Nothing leaves your network.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get turnOff => 'Turn off mirroring';

  @override
  String get accessOn => 'Notification access is on';

  @override
  String get accessOff => 'Notification access is off';

  @override
  String get accessStillOff =>
      'Still off. Turn on Ferret on the Notification access screen, then come back.';

  @override
  String get accessHowTo =>
      'On the next screen, turn on Ferret, then come back here.';

  @override
  String get openAccessSettings => 'Open notification access';

  @override
  String get openSettingsFailed =>
      'Couldn\'t open Settings. Open Settings → Notifications → Notification access yourself.';

  @override
  String get restrictedTitle => 'Android blocked this setting';

  @override
  String get restrictedBody =>
      'Android blocks it for apps installed outside an app store. Allow it once:';

  @override
  String get restrictedStepOne => 'Open App info.';

  @override
  String get restrictedStepTwo =>
      'Tap ⋮ in the top corner, then Allow restricted settings.';

  @override
  String get restrictedStepThree =>
      'Come back and open notification access again.';

  @override
  String get openAppInfo => 'Open App info';

  @override
  String get skipWhileUsing => 'Pause while I\'m using the phone';

  @override
  String get skipWhileUsingDetail =>
      'When the screen is on and unlocked, you already see them there.';

  @override
  String get chooseApps => 'Choose apps';

  @override
  String appCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps picked',
      one: '1 app picked',
      zero: 'No apps picked',
    );
    return '$_temp0';
  }

  @override
  String get appPickerTitle => 'Apps to mirror';

  @override
  String get appPickerSearch => 'Search apps';

  @override
  String get appPickerMessaging => 'Messaging apps';

  @override
  String get appPickerOther => 'Other apps';

  @override
  String get appPickerLoading => 'Getting the apps…';

  @override
  String get appPickerEmpty => 'No apps match.';

  @override
  String appPickerFailed(String device) {
    return 'Couldn\'t get the apps from $device. Make sure it\'s connected.';
  }

  @override
  String appPickerSaveFailed(String device) {
    return 'Couldn\'t save that change on $device.';
  }

  @override
  String get thisPhone => 'this phone';

  @override
  String get tryAgain => 'Try again';

  @override
  String get back => 'Back';

  @override
  String get noPhone =>
      'Connect your Android phone to see its notifications here.';

  @override
  String phoneMirroring(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
      zero: 'no apps',
    );
    return 'Mirroring $_temp0';
  }

  @override
  String get phoneMirroringOff =>
      'Mirroring is off. Turn it on in Ferret on the phone.';

  @override
  String get phoneAccessOff =>
      'Notification access is off. Open Ferret on the phone to fix it.';

  @override
  String get phoneChecking => 'Checking…';

  @override
  String get phoneUnreachable => 'Couldn\'t reach notifications on this phone.';

  @override
  String get homeEmpty =>
      'No notifications yet. New ones from your phone show up here.';

  @override
  String get clearAll => 'Clear all';

  @override
  String get reply => 'Reply';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get offline => 'offline';

  @override
  String whileAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications while away',
      one: '1 notification while away',
    );
    return '$_temp0';
  }

  @override
  String whileAwayFrom(int count, String apps) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications while away',
      one: '1 notification while away',
    );
    return '$_temp0, from $apps';
  }

  @override
  String get replyFailedTitle => 'Reply not sent';

  @override
  String replyFailedBody(String device) {
    return '$device is offline or the notification is gone. Reply on the phone.';
  }

  @override
  String get setUp => 'Set up';

  @override
  String get fix => 'Fix';

  @override
  String get phoneHomePaused =>
      'Notification access is off, so nothing is mirrored.';

  @override
  String homeTurnOn(String device) {
    return 'Turn on Notifications on $device to see its notifications here.';
  }

  @override
  String homeOffline(String device) {
    return '$device is offline. Notifications show here when it\'s back.';
  }

  @override
  String homeAccessOff(String device) {
    return 'Notification access is off on $device. Open Ferret on $device to fix it.';
  }

  @override
  String homeUnreachable(String device) {
    return 'Couldn\'t reach notifications on $device.';
  }

  @override
  String howTitle(String device) {
    return 'Turn on Notifications on $device';
  }

  @override
  String howBody(String device) {
    return 'On $device, open Ferret, tap Turn on more, then Notifications. Ferret asks for notification access and lets you pick the apps.';
  }

  @override
  String get how => 'How?';

  @override
  String get ok => 'OK';
}
