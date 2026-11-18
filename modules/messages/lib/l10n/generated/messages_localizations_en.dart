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
      'Ferret reads SMS and MMS on this phone and sends them only to your paired computers, over your own network. Contacts give conversations names and photos.';

  @override
  String get rcsNote =>
      'RCS chats live inside Google Messages, and no other app can read them. Notification mirroring covers them: allow Google Messages in Notifications to see and answer them on your computer.';

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
      'Settings couldn\'t be opened on this phone.';

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
      'Messages are on, but Ferret can\'t read your texts yet.';

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
    return 'Messages are off on $name. Open Ferret on the phone and turn them on.';
  }

  @override
  String statusNoAccess(String name) {
    return 'Ferret on $name can\'t read texts yet. Open Ferret on the phone and allow SMS.';
  }

  @override
  String statusUnreachable(String name) {
    return '$name didn\'t answer. Check that Ferret is open on the phone, then try again.';
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
    return 'Connect $name to reply.';
  }

  @override
  String get composerGroup =>
      'Group texts need MMS, which only your phone\'s messaging app can send. Reply on the phone.';

  @override
  String get composerNoSend =>
      'Sending is off on the phone. Allow SMS in Ferret on the phone to reply from here.';

  @override
  String get sending => 'Sending…';

  @override
  String get notSent => 'Not sent';

  @override
  String get outcomeOffline => 'The phone isn\'t connected.';

  @override
  String get outcomeNoAccess => 'Ferret may not send texts on the phone.';

  @override
  String get outcomeNoRecipient => 'This conversation has no one to send to.';

  @override
  String get outcomeGroup => 'Group texts can only be sent from the phone.';

  @override
  String get outcomeNoService => 'The phone has no signal.';

  @override
  String get outcomeTimeout =>
      'The phone didn\'t confirm in time. Check the conversation on the phone before sending again.';

  @override
  String get outcomeFailed => 'The phone couldn\'t send it.';

  @override
  String get retrySend => 'Retry';

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
      'RCS chats don\'t show here. Mirror Google Messages\' notifications to answer them.';

  @override
  String get replyAction => 'Reply';

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
