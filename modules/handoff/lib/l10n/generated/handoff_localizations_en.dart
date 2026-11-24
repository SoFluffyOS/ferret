// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'handoff_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class HandoffLocalizationsEn extends HandoffLocalizations {
  HandoffLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Continue';

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
    return 'On $device: tap the notification to open it.';
  }

  @override
  String sendFailed(String device) {
    return '$device couldn\'t open it. It may need an app that isn\'t installed there.';
  }

  @override
  String sendUnreachable(String device) {
    return 'Couldn\'t reach $device. Check that it\'s on and on the same Wi-Fi.';
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
  String get settingsAssistantOpen => 'Assistant settings';

  @override
  String get settingsShareHint =>
      'You can also share any link to “Send with Ferret” and pick “Open on…”.';

  @override
  String get summaryPassive => 'Offers the page you\'re on';

  @override
  String get summarySendsOnly => 'Only what you send';

  @override
  String get summaryBrowserOff => 'Off';

  @override
  String get summaryNoBrowser => 'No browser yet';

  @override
  String healthUnsupported(String name) {
    return 'Needs a Ferret update on $name';
  }

  @override
  String healthOpensRightAway(String name) {
    return 'Links from $name open right away';
  }

  @override
  String healthWaits(String name) {
    return 'Links from $name wait in a notification';
  }

  @override
  String healthLastSendFailed(String name) {
    return '$name didn\'t get the last link you sent';
  }

  @override
  String healthLastSendFailedHelp(String name) {
    return 'On $name: open Ferret, then send the link again.';
  }

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
      'Check that it\'s on and on the same Wi-Fi, then share it again.';

  @override
  String get noticeNothingToSend =>
      'There was nothing to continue in what you shared.';

  @override
  String get pickDeviceTitle => 'Continue on';

  @override
  String get pickDeviceEmpty =>
      'No device is connected right now. Open Ferret on your other device, on the same Wi-Fi.';

  @override
  String get back => 'Back';

  @override
  String browserPairTitle(String browser) {
    return 'Allow $browser to use Ferret?';
  }

  @override
  String browserPairBody(String code) {
    return 'Check that your browser shows $code. It can then send tabs to your devices and open the pages they send here.';
  }

  @override
  String get browserPairAllow => 'Allow';

  @override
  String get browserPairDeny => 'Don\'t allow';

  @override
  String noticeBrowserPairBody(String code) {
    return 'Code $code. Open Ferret to allow it.';
  }

  @override
  String get settingsBrowserBridge => 'Browser extension';

  @override
  String settingsBrowserBridgeBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Lets the Ferret extension in Chrome, Edge, Brave or Firefox send tabs and open pages from your devices. It only listens on $_temp0.';
  }

  @override
  String get browserBridgeListening =>
      'To add another browser, pair from the extension\'s settings page.';

  @override
  String get browserBridgeFailed =>
      'Ferret couldn\'t start the browser connection. Another copy of Ferret may be running: quit it, then try again.';

  @override
  String get browserBridgeRetry => 'Try again';

  @override
  String get browserClientsEmpty =>
      'No browser yet. Install the extension, open its settings and choose “Pair with Ferret”.';

  @override
  String get browserClientConnected => 'Connected';

  @override
  String get browserClientOffline => 'Not connected';

  @override
  String get browserClientRemove => 'Remove';

  @override
  String continueUntitledFrom(String device) {
    return 'Continue from $device';
  }

  @override
  String get settingsHistory => 'History';

  @override
  String get settingsHistoryBody =>
      'What you continued between devices, kept on this device for 30 days at most.';

  @override
  String get settingsHistoryClear => 'Clear';

  @override
  String healthLastOpenFailed(String name) {
    return '$name couldn\'t open the last link you sent';
  }

  @override
  String healthLastOpenFailedHelp(String name) {
    return 'It waits in Activity on $name, with Copy and Open.';
  }

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String activityReceived(String device) {
    return 'From $device';
  }

  @override
  String activityReceivedNotOpened(String device) {
    return 'Couldn\'t open what $device sent';
  }

  @override
  String activitySent(String device) {
    return 'Sent to $device';
  }

  @override
  String activitySentNotOpened(String device) {
    return '$device couldn\'t open it';
  }

  @override
  String noticeOpenFailedTitle(String title) {
    return 'Couldn\'t open “$title”';
  }
}
