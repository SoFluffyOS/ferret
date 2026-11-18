// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'iphone_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class IphoneLocalizationsEn extends IphoneLocalizations {
  IphoneLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'iPhone';

  @override
  String nowPlayingOn(String device) {
    return 'Now playing on $device';
  }

  @override
  String pausedOn(String device) {
    return 'Paused on $device';
  }

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get volumeUp => 'Volume up';

  @override
  String get volumeDown => 'Volume down';

  @override
  String commandFailed(String device) {
    return '$device didn\'t answer. Keep it near this computer, then try again.';
  }

  @override
  String get problemBluetoothOffTitle => 'Bluetooth is off';

  @override
  String get problemBluetoothOffBody =>
      'Turn on Bluetooth on this computer to get your iPhone\'s notifications and media here.';

  @override
  String get problemUnauthorizedTitle => 'Ferret can\'t use Bluetooth';

  @override
  String get problemUnauthorizedBody =>
      'Allow Bluetooth for Ferret in this computer\'s privacy settings, then try again.';

  @override
  String get problemNoDeviceTitle => 'Pick your iPhone';

  @override
  String get problemNoDeviceBody =>
      'Pair it with this computer, then choose it in Ferret.';

  @override
  String problemNotSharedTitle(String device) {
    return '$device isn\'t sharing with this computer';
  }

  @override
  String problemNotSharedBody(String device) {
    return 'On $device: Settings → Bluetooth, tap ⓘ next to this computer, then turn on Share System Notifications. Not listed there? Pair it again.';
  }

  @override
  String get yourIphone => 'iPhone';

  @override
  String get openBluetoothSettings => 'Open Bluetooth settings';

  @override
  String get openFailed =>
      'Couldn\'t open the Bluetooth settings. Open them from your system settings.';

  @override
  String get setUp => 'Set up';

  @override
  String get tryAgain => 'Try again';

  @override
  String get settingsEnable => 'Connect an iPhone';

  @override
  String get settingsEnableBody =>
      'Shows its notifications and what it plays, over Bluetooth. Nothing to install on the iPhone.';

  @override
  String get worksTitle => 'What works with an iPhone';

  @override
  String get worksBody =>
      'Notifications as they arrive, with Clear, Answer and Decline. Play, pause, skip and volume for whatever the iPhone plays.';

  @override
  String get limitsTitle => 'Not yet';

  @override
  String get limitsBody =>
      'Reading and sending texts (SMS and iMessage) and taking calls on this computer. Apple keeps files, clipboard and handoff to its own devices.';

  @override
  String get macNoteTitle => 'Experimental on a Mac';

  @override
  String get macNote =>
      'It only works while macOS itself is connected to the iPhone over Bluetooth, and macOS may keep the iPhone\'s notifications to itself.';

  @override
  String get statusUnsupported =>
      'This computer has no Bluetooth LE, which the iPhone link needs.';

  @override
  String get statusNotConfigured =>
      'This build of Ferret isn\'t allowed to use Bluetooth.';

  @override
  String statusConnecting(String device) {
    return 'Connecting to $device…';
  }

  @override
  String statusConnected(String device) {
    return 'Connected to $device';
  }

  @override
  String statusOutOfReach(String device) {
    return '$device is out of reach. Ferret reconnects when it\'s back.';
  }

  @override
  String statusFailed(String device) {
    return 'Couldn\'t talk to $device. Trying again shortly.';
  }

  @override
  String get summaryUnavailable => 'Not available on this computer';

  @override
  String summaryOutOfReach(String device) {
    return '$device is out of reach';
  }

  @override
  String summaryNotShared(String device) {
    return '$device isn\'t sharing';
  }

  @override
  String notificationsNotShared(String device) {
    return '$device isn\'t sharing its notifications. On $device: Settings → Bluetooth, tap ⓘ next to this computer, then turn on Share System Notifications.';
  }

  @override
  String mediaNotShared(String device) {
    return '$device isn\'t sharing what it plays with this computer.';
  }

  @override
  String get setupTitle => 'Pair your iPhone';

  @override
  String get setupStepUnlock =>
      'On the iPhone: unlock it and open Settings → Bluetooth. Keep that screen open.';

  @override
  String get setupStepPairWindows =>
      'On this PC, open Bluetooth settings, choose Add device → Bluetooth and pick the iPhone. Confirm the code on both.';

  @override
  String get setupStepPairMac =>
      'Keep the iPhone signed in and near this Mac with Bluetooth on, so macOS connects to it.';

  @override
  String get setupStepPairLinux =>
      'This computer now shows up on the iPhone under Other Devices. Tap it there, and confirm the code on both.';

  @override
  String get setupStepAllow =>
      'When the iPhone asks, allow it to show notifications on this computer.';

  @override
  String get setupStepChoose => 'Choose the iPhone below.';

  @override
  String get devicesTitle => 'Paired devices';

  @override
  String get devicesEmpty => 'No paired iPhone found yet.';

  @override
  String get devicesRefresh => 'Look again';

  @override
  String get deviceUse => 'Use';

  @override
  String get deviceConnected => 'Connected';

  @override
  String get deviceUnnamed => 'Unnamed device';

  @override
  String get forget => 'Use another iPhone';

  @override
  String get settingsNotifications => 'Show notifications';

  @override
  String get settingsNotificationsBody =>
      'New ones only. What was already on the iPhone stays there.';

  @override
  String get settingsMedia => 'Media controls';

  @override
  String get settingsMediaBody =>
      'A card with what the iPhone plays, and its controls.';

  @override
  String get settingsHidePreviews => 'Hide what notifications say';

  @override
  String get settingsHidePreviewsBody =>
      'Show only which app it is, for when others can see your screen.';

  @override
  String noticeTitle(String app, String title) {
    return '$app: $title';
  }

  @override
  String get noticeHidden => 'New notification';

  @override
  String get noticeFromIphone => 'iPhone';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionAnswer => 'Answer';

  @override
  String get actionDecline => 'Decline';

  @override
  String get actionCallBack => 'Call back';

  @override
  String get actionAccept => 'Accept';

  @override
  String actionFailedTitle(String device) {
    return '$device didn\'t answer';
  }

  @override
  String actionFailedBody(String device) {
    return 'That didn\'t reach $device. Keep it near this computer, then try again.';
  }
}
