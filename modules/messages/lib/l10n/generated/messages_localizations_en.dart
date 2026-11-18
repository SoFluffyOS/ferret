// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'messages_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class MessagesLocalizationsEn extends MessagesLocalizations {
  MessagesLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Messages';

  @override
  String get back => 'Back';

  @override
  String get explainer => 'Read and reply to your texts from your computer.';

  @override
  String get explainerDetail =>
      'Ferret reads the texts on this phone and shows them only on your own computers. Nothing leaves your network. Contacts give conversations names and photos.';

  @override
  String get rcsNote =>
      'Chats in Google Messages (RCS, the ones with typing dots) can\'t be read by other apps. They still reach your computer as notifications, and you can answer them there.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get turnOff => 'Turn off';

  @override
  String get noTelephony =>
      'This device can\'t send or receive texts, so there is nothing to share.';

  @override
  String get accessOff => 'SMS access is off';

  @override
  String get accessStillOff =>
      'Still off. Allow SMS so Ferret can read your texts.';

  @override
  String get accessHowTo =>
      'Ferret needs SMS to read and send texts, and Contacts to show names.';

  @override
  String get allowAccess => 'Allow access';

  @override
  String get accessBlocked =>
      'Android won\'t ask again. Open Ferret\'s settings, tap Permissions, then allow SMS and Contacts.';

  @override
  String get openAppSettings => 'Open settings';

  @override
  String get openSettingsFailed =>
      'Couldn\'t open Settings. Open Android Settings → Apps → Ferret → Permissions yourself.';

  @override
  String get accessOn => 'Your computers can read and reply to your texts';

  @override
  String get contactsOff =>
      'Contacts are off, so conversations show numbers instead of names.';

  @override
  String get sendOff =>
      'Sending is off, so replies from your computer won\'t go out.';

  @override
  String get offerDescription => 'Read and reply to texts from your computer.';

  @override
  String get phoneCardNeedsAccess =>
      'Messages are on, but Ferret can\'t read this phone\'s texts yet.';

  @override
  String get fix => 'Fix';

  @override
  String get setUp => 'Set up';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread texts',
      one: '1 unread text',
      zero: 'No unread texts',
    );
    return '$_temp0';
  }

  @override
  String get open => 'Open';

  @override
  String get conversationsEmpty => 'No conversations yet.';

  @override
  String statusOffline(String name) {
    return '$name is offline. You can read saved texts and reply once it\'s back.';
  }

  @override
  String statusChecking(String name) {
    return 'Connecting to $name…';
  }

  @override
  String statusOff(String name) {
    return 'Messages are off on $name. On $name: Ferret → Do more → Messages.';
  }

  @override
  String statusNoAccess(String name) {
    return 'Ferret on $name can\'t read texts yet. On $name: open Ferret and allow SMS.';
  }

  @override
  String statusUnreachable(String name) {
    return '$name didn\'t answer. On $name: open Ferret, then try again.';
  }

  @override
  String get healthOk => 'Texts and replies';

  @override
  String healthOff(String name) {
    return 'Off on $name';
  }

  @override
  String get healthNoAccess => 'Android turned off Ferret\'s access';

  @override
  String get healthChecking => 'Checking…';

  @override
  String healthOffHelp(String name) {
    return 'On $name: Ferret → Do more → Messages.';
  }

  @override
  String healthNoAccessHelp(String name) {
    return 'On $name: open Ferret and allow SMS.';
  }

  @override
  String get healthOffThisPhone => 'Off on this phone';

  @override
  String get healthOffThisPhoneHelp =>
      'On this phone: Settings → To your computer → Messages.';

  @override
  String get settingsNeedsAccess => 'Needs access';

  @override
  String settingsNeedsAccessOn(String name) {
    return 'Needs access on $name';
  }

  @override
  String healthUnreachable(String name) {
    return '$name didn\'t answer';
  }

  @override
  String get retry => 'Try again';

  @override
  String get syncing => 'Syncing recent conversations…';

  @override
  String get loadingOlder => 'Loading older texts…';

  @override
  String loadFailed(String name) {
    return 'Couldn\'t load texts from $name.';
  }

  @override
  String get pickConversation => 'Pick a conversation';

  @override
  String get composerHint => 'Text message';

  @override
  String get send => 'Send';

  @override
  String composerOffline(String name) {
    return 'Reply once $name is back.';
  }

  @override
  String composerGroup(String name) {
    return 'Group texts need MMS, which only $name\'s messaging app can send. Reply on $name.';
  }

  @override
  String composerNoSend(String name) {
    return 'Sending is off on $name. On $name: open Ferret and allow SMS to reply from here.';
  }

  @override
  String get sending => 'Sending…';

  @override
  String get notSent => 'Not sent';

  @override
  String outcomeOffline(String name) {
    return '$name isn\'t connected.';
  }

  @override
  String outcomeNoAccess(String name) {
    return 'Ferret isn\'t allowed to send texts on $name. On $name: open Ferret and allow SMS.';
  }

  @override
  String get outcomeNoRecipient => 'This conversation has no one to send to.';

  @override
  String outcomeGroup(String name) {
    return 'Group texts can only be sent from $name.';
  }

  @override
  String outcomeNoService(String name) {
    return '$name has no signal.';
  }

  @override
  String outcomeTimeout(String name) {
    return '$name didn\'t confirm in time. Check the conversation on $name before sending again.';
  }

  @override
  String outcomeFailed(String name) {
    return '$name couldn\'t send it. Send again, or send it from $name.';
  }

  @override
  String get retrySend => 'Send again';

  @override
  String get discard => 'Discard';

  @override
  String get kindFailed => 'Not delivered';

  @override
  String get kindQueued => 'Waiting to send';

  @override
  String get kindOutbox => 'Sending…';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get audio => 'Audio';

  @override
  String get contactCard => 'Contact';

  @override
  String get attachment => 'Attachment';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get you => 'You';

  @override
  String imageFailed(String name) {
    return 'Couldn\'t load the picture from $name.';
  }

  @override
  String get rcsComputerNote =>
      'RCS chats don\'t show here. They arrive with your phone\'s notifications, where you can answer them.';

  @override
  String get replyAction => 'Reply';

  @override
  String activityTitle(String sender, String device) {
    return '$sender · $device';
  }

  @override
  String get markReadAction => 'Mark as read';

  @override
  String get replyFailedTitle => 'Reply not sent';

  @override
  String noticeTitleCount(String name, int count) {
    return '$name · $count new';
  }

  @override
  String noticeGroupBody(String sender, String text) {
    return '$sender: $text';
  }

  @override
  String get notifySetting => 'Show new texts as notifications';

  @override
  String get notifyDetail =>
      'With Reply, unless the conversation is already open here.';

  @override
  String get forgetHistory => 'Forget saved texts';

  @override
  String get forgetDetail =>
      'Ferret keeps recent texts on this computer so they show while the phone is offline.';

  @override
  String get forgetConfirmTitle => 'Forget saved texts?';

  @override
  String get forgetConfirmBody =>
      'This deletes the texts saved on this computer. Your phone keeps them all.';

  @override
  String get forgetConfirm => 'Forget';

  @override
  String get cancel => 'Cancel';
}
