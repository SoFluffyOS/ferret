// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'handoff_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class HandoffLocalizationsEn extends HandoffLocalizations {
  HandoffLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Handoff';

  @override
  String get cardTitle => 'Continue';

  @override
  String continueFrom(String title, String device) {
    return 'Continue “$title” from $device';
  }

  @override
  String get open => 'Open';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get cancel => 'Cancel';

  @override
  String get openFailed =>
      'This device can\'t open that. It may need an app that isn\'t installed here.';

  @override
  String get openDeferred => 'Open Ferret to continue it.';

  @override
  String get actionSendLink => 'Send a link…';

  @override
  String get actionSendCurrentPage => 'Send current page';

  @override
  String sendLinkTitle(String device) {
    return 'Send to $device';
  }

  @override
  String get sendLinkLabel => 'Link or text';

  @override
  String get sendLinkHint => 'https://…';

  @override
  String get send => 'Send';

  @override
  String get sendEmpty => 'Nothing to send. Paste a link or some text.';

  @override
  String sendOpened(String device) {
    return 'Opened on $device';
  }

  @override
  String sendSuggested(String device) {
    return 'Waiting on $device: tap the notification there to open it';
  }

  @override
  String sendFailed(String device) {
    return '$device couldn\'t open it. It may need an app that isn\'t installed there.';
  }

  @override
  String sendUnreachable(String device) {
    return 'Couldn\'t reach $device. Check that it\'s on and on the same network.';
  }

  @override
  String get currentPageNone =>
      'No browser page found. Open a page in Safari or a Chromium browser, then try again.';

  @override
  String get currentPageDenied =>
      'macOS blocked Ferret from reading your browser. Allow it in System Settings, Privacy & Security, Automation.';

  @override
  String get currentPageFailed =>
      'Couldn\'t read the browser page. Try again, or send the link with “Send a link…”.';

  @override
  String get settingsPassive => 'Suggest what I\'m doing';

  @override
  String get settingsPassiveBody =>
      'Your other devices quietly offer to continue the page you\'re on. Suggestions go away after 5 minutes.';

  @override
  String get settingsOpenAutomatically => 'Open sent links right away';

  @override
  String get settingsOpenAutomaticallyBody =>
      'When off, things sent here wait in a notification until you open them.';

  @override
  String get settingsBrowserTab => 'Read the current browser page';

  @override
  String get settingsBrowserTabBody =>
      'Adds “Send current page”, and suggests the page you leave. macOS asks once per browser.';

  @override
  String get settingsAssistantTitle => 'Continue from any app';

  @override
  String get settingsAssistantBody =>
      'Make Ferret your digital assistant, then long-press Home (or swipe up from a bottom corner) on any screen to send it to another device. Turn on “Use text from screen” on the same settings page.';

  @override
  String get settingsAssistantOn => 'Ferret is your assistant';

  @override
  String get settingsAssistantOff => 'Ferret isn\'t your assistant yet';

  @override
  String get settingsAssistantOpen => 'Open assistant settings';

  @override
  String get settingsShareHint =>
      'You can also share any link to “Continue on…”.';

  @override
  String noticeTitle(String title) {
    return 'Continue “$title”';
  }

  @override
  String noticeFrom(String device) {
    return 'From $device';
  }

  @override
  String noticeTextCopied(String device) {
    return 'Copied text from $device';
  }

  @override
  String noticeSent(String device) {
    return 'Sent to $device';
  }

  @override
  String noticeNotSent(String device) {
    return 'Couldn\'t send to $device';
  }

  @override
  String get noticeNotSentBody =>
      'Check that it\'s on and on the same network, then share it again.';

  @override
  String get noticeNothingToSend =>
      'There was nothing to continue in what you shared.';

  @override
  String get pickDeviceTitle => 'Continue on';

  @override
  String get pickDeviceEmpty =>
      'No device is connected right now. Turn on your other device and keep it on the same network.';

  @override
  String get back => 'Back';
}
