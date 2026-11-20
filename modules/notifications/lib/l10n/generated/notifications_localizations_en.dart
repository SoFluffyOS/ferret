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
  String explainer(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return 'Shows $_temp0 notifications on your computer. Every app comes through, and you can mute the ones you don\'t want.';
  }

  @override
  String offerDescription(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return 'See $_temp0 notifications on your computer.';
  }

  @override
  String get explainerDetail =>
      'Only new notifications. Nothing leaves your network.';

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
  String get openAccessShort => 'Open settings';

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
  String get appsAll => 'All apps';

  @override
  String appsAllExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All apps except $count',
      one: 'All apps except 1',
      zero: 'All apps',
    );
    return '$_temp0';
  }

  @override
  String appsOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
      zero: 'No apps picked',
    );
    return '$_temp0';
  }

  @override
  String get filterAll => 'All apps';

  @override
  String get filterAllDetail =>
      'Every app\'s notifications come to your computer.';

  @override
  String get filterAllExcept => 'All apps except…';

  @override
  String get filterAllExceptDetail => 'Mute a few noisy apps.';

  @override
  String get filterOnly => 'Only these apps…';

  @override
  String get filterOnlyDetail => 'Pick the few apps you want.';

  @override
  String get filterBuiltIn =>
      'Ferret\'s own notifications, music controls and silent or ongoing ones always stay on the phone.';

  @override
  String get appPickerMuteHint =>
      'Switch off the apps you don\'t want on your computer.';

  @override
  String get appPickerOnlyHint =>
      'Switch on the apps you want on your computer.';

  @override
  String get appPickerApps => 'Apps, most recent first';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectNone => 'Select none';

  @override
  String get appPickerTitle => 'Choose apps';

  @override
  String get appPickerSearch => 'Search apps';

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
  String thisPhone(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return '$_temp0';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get back => 'Back';

  @override
  String get noPhone =>
      'Connect your Android phone to see its notifications here.';

  @override
  String phoneMirroring(String apps) {
    return 'On · $apps';
  }

  @override
  String phoneMirroringOff(String device) {
    return 'Off on $device';
  }

  @override
  String get phoneAccessOff => 'Android turned off Ferret\'s access';

  @override
  String get phoneChecking => 'Checking…';

  @override
  String phoneUnreachable(String device) {
    return '$device didn\'t answer';
  }

  @override
  String get homeEmpty =>
      'No notifications yet. New ones from your phone show up here.';

  @override
  String homeEmptyFrom(String device) {
    return 'No notifications yet. New ones from $device show up here.';
  }

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
    return '$device is offline or the notification is gone. Reply on $device.';
  }

  @override
  String get setUp => 'Set up';

  @override
  String get fix => 'Fix';

  @override
  String phoneHomePaused(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'Notification access is off on $_temp0, so your computer gets no notifications.';
  }

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
    return 'Android turned off Ferret\'s access on $device. On $device: open Ferret and tap Fix.';
  }

  @override
  String homeUnreachable(String device) {
    return '$device didn\'t answer. On $device: open Ferret.';
  }

  @override
  String howTitle(String device) {
    return 'Turn on Notifications on $device';
  }

  @override
  String howBody(String device) {
    return 'On $device: Ferret → Do more → Notifications. Ferret asks for notification access, then every app\'s notifications show here.';
  }

  @override
  String get how => 'How?';

  @override
  String get ok => 'Got it';

  @override
  String get settingsNeedsAccess => 'Needs access';

  @override
  String settingsNeedsAccessOn(String device) {
    return 'Needs access on $device';
  }

  @override
  String get settingsPerPhone =>
      'Every app comes through unless you change it. To mute apps or stop showing a phone here, open the phone from Home.';

  @override
  String get permissionShow => 'Show its notifications here';

  @override
  String get permissionHold => 'Hold them back while it\'s in use';

  @override
  String get actionChooseApps => 'Choose notification apps';

  @override
  String get actionChooseAppsShort => 'Choose apps';

  @override
  String get healthHiddenHere => 'Turned off here';

  @override
  String get healthHiddenHelp =>
      'Turn on \"Show its notifications here\" below.';

  @override
  String healthAccessHelp(String device) {
    return 'On $device: open Ferret and tap Fix.';
  }

  @override
  String healthOffThisPhone(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'Off on $_temp0';
  }

  @override
  String healthOffThisPhoneHelp(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'On $_temp0: Settings → To your computer → Notifications.';
  }

  @override
  String activityOne(String app, String title) {
    return '$app: $title';
  }

  @override
  String activityCount(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications from $device',
      one: '1 notification from $device',
    );
    return '$_temp0';
  }

  @override
  String privateCover(String device) {
    return 'New notification from $device';
  }

  @override
  String get hideCodes => 'Hide one-time codes';

  @override
  String hideCodesDetail(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'Sign-in, bank and delivery codes stay on $_temp0. Computers show the app and \"Code hidden\".';
  }

  @override
  String get codeHidden => 'Code hidden. Open it on the phone.';
}
