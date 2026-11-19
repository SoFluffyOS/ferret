import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'messages_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of MessagesLocalizations
/// returned by `MessagesLocalizations.of(context)`.
///
/// Applications need to include `MessagesLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/messages_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: MessagesLocalizations.localizationsDelegates,
///   supportedLocales: MessagesLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the MessagesLocalizations.supportedLocales
/// property.
abstract class MessagesLocalizations {
  MessagesLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static MessagesLocalizations of(BuildContext context) {
    return Localizations.of<MessagesLocalizations>(
      context,
      MessagesLocalizations,
    )!;
  }

  static const LocalizationsDelegate<MessagesLocalizations> delegate =
      _MessagesLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get title;

  /// Title of the Messages card and page: the feature, then the phone the texts come from
  ///
  /// In en, this message translates to:
  /// **'Messages · {phone}'**
  String cardTitle(String phone);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @explainer.
  ///
  /// In en, this message translates to:
  /// **'Read and reply to your texts from your computer.'**
  String get explainer;

  /// No description provided for @explainerDetail.
  ///
  /// In en, this message translates to:
  /// **'Ferret reads the texts on this phone and shows them only on your own computers. Nothing leaves your network. Contacts give conversations names and photos.'**
  String get explainerDetail;

  /// No description provided for @rcsNote.
  ///
  /// In en, this message translates to:
  /// **'Chats in Google Messages (RCS, the ones with typing dots) can\'t be read by other apps. They still reach your computer as notifications, and you can answer them there.'**
  String get rcsNote;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turnOff;

  /// No description provided for @noTelephony.
  ///
  /// In en, this message translates to:
  /// **'This device can\'t send or receive texts, so there is nothing to share.'**
  String get noTelephony;

  /// No description provided for @accessOff.
  ///
  /// In en, this message translates to:
  /// **'SMS access is off'**
  String get accessOff;

  /// No description provided for @accessStillOff.
  ///
  /// In en, this message translates to:
  /// **'Still off. Allow SMS so Ferret can read your texts.'**
  String get accessStillOff;

  /// No description provided for @accessHowTo.
  ///
  /// In en, this message translates to:
  /// **'Ferret needs SMS to read and send texts, and Contacts to show names.'**
  String get accessHowTo;

  /// No description provided for @allowAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get allowAccess;

  /// No description provided for @accessBlocked.
  ///
  /// In en, this message translates to:
  /// **'Android won\'t ask again. Open Ferret\'s settings, tap Permissions, then allow SMS and Contacts.'**
  String get accessBlocked;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openAppSettings;

  /// No description provided for @openSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Settings. Open Android Settings → Apps → Ferret → Permissions yourself.'**
  String get openSettingsFailed;

  /// No description provided for @accessOn.
  ///
  /// In en, this message translates to:
  /// **'Your computers can read and reply to your texts'**
  String get accessOn;

  /// No description provided for @contactsOff.
  ///
  /// In en, this message translates to:
  /// **'Contacts are off, so conversations show numbers instead of names.'**
  String get contactsOff;

  /// No description provided for @sendOff.
  ///
  /// In en, this message translates to:
  /// **'Sending is off, so replies from your computer won\'t go out.'**
  String get sendOff;

  /// No description provided for @offerDescription.
  ///
  /// In en, this message translates to:
  /// **'Read and reply to texts from your computer.'**
  String get offerDescription;

  /// No description provided for @phoneCardNeedsAccess.
  ///
  /// In en, this message translates to:
  /// **'Messages are on, but Ferret can\'t read this phone\'s texts yet.'**
  String get phoneCardNeedsAccess;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @setUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get setUp;

  /// No description provided for @unreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread texts} =1{1 unread text} other{{count} unread texts}}'**
  String unreadCount(int count);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @conversationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.'**
  String get conversationsEmpty;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'{name} is offline. You can read saved texts and reply once it\'s back.'**
  String statusOffline(String name);

  /// No description provided for @statusChecking.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {name}…'**
  String statusChecking(String name);

  /// No description provided for @statusOff.
  ///
  /// In en, this message translates to:
  /// **'Messages are off on {name}. On {name}: Ferret → Do more → Messages.'**
  String statusOff(String name);

  /// No description provided for @statusNoAccess.
  ///
  /// In en, this message translates to:
  /// **'Ferret on {name} can\'t read texts yet. On {name}: open Ferret and allow SMS.'**
  String statusNoAccess(String name);

  /// No description provided for @statusUnreachable.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t answer. On {name}: open Ferret, then try again.'**
  String statusUnreachable(String name);

  /// Device page, next to Messages, while it works.
  ///
  /// In en, this message translates to:
  /// **'Texts and replies'**
  String get healthOk;

  /// Device page, next to Messages.
  ///
  /// In en, this message translates to:
  /// **'Off on {name}'**
  String healthOff(String name);

  /// Device page, next to Messages.
  ///
  /// In en, this message translates to:
  /// **'Android turned off Ferret\'s access'**
  String get healthNoAccess;

  /// No description provided for @healthChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get healthChecking;

  /// No description provided for @healthOffHelp.
  ///
  /// In en, this message translates to:
  /// **'On {name}: Ferret → Do more → Messages.'**
  String healthOffHelp(String name);

  /// No description provided for @healthNoAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'On {name}: open Ferret and allow SMS.'**
  String healthNoAccessHelp(String name);

  /// No description provided for @healthOffThisPhone.
  ///
  /// In en, this message translates to:
  /// **'Off on this phone'**
  String get healthOffThisPhone;

  /// No description provided for @healthOffThisPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'On this phone: Settings → To your computer → Messages.'**
  String get healthOffThisPhoneHelp;

  /// Settings row value on the phone: Messages are on but Android doesn't let Ferret read texts.
  ///
  /// In en, this message translates to:
  /// **'Needs access'**
  String get settingsNeedsAccess;

  /// Settings row value on a computer.
  ///
  /// In en, this message translates to:
  /// **'Needs access on {name}'**
  String settingsNeedsAccessOn(String name);

  /// Device page, next to Messages.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t answer'**
  String healthUnreachable(String name);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing recent conversations…'**
  String get syncing;

  /// No description provided for @loadingOlder.
  ///
  /// In en, this message translates to:
  /// **'Loading older texts…'**
  String get loadingOlder;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load texts from {name}.'**
  String loadFailed(String name);

  /// No description provided for @pickConversation.
  ///
  /// In en, this message translates to:
  /// **'Pick a conversation'**
  String get pickConversation;

  /// No description provided for @composerHint.
  ///
  /// In en, this message translates to:
  /// **'Text message'**
  String get composerHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @composerOffline.
  ///
  /// In en, this message translates to:
  /// **'Reply once {name} is back.'**
  String composerOffline(String name);

  /// No description provided for @composerGroup.
  ///
  /// In en, this message translates to:
  /// **'Group texts need MMS, which only {name}\'s messaging app can send. Reply on {name}.'**
  String composerGroup(String name);

  /// No description provided for @composerNoSend.
  ///
  /// In en, this message translates to:
  /// **'Sending is off on {name}. On {name}: open Ferret and allow SMS to reply from here.'**
  String composerNoSend(String name);

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @notSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get notSent;

  /// Under a text that failed to send. The reason is a full sentence
  ///
  /// In en, this message translates to:
  /// **'Not sent. {reason}'**
  String notSentBecause(String reason);

  /// No description provided for @outcomeOffline.
  ///
  /// In en, this message translates to:
  /// **'{name} isn\'t connected.'**
  String outcomeOffline(String name);

  /// No description provided for @outcomeNoAccess.
  ///
  /// In en, this message translates to:
  /// **'Ferret isn\'t allowed to send texts on {name}. On {name}: open Ferret and allow SMS.'**
  String outcomeNoAccess(String name);

  /// No description provided for @outcomeNoRecipient.
  ///
  /// In en, this message translates to:
  /// **'This conversation has no one to send to.'**
  String get outcomeNoRecipient;

  /// No description provided for @outcomeGroup.
  ///
  /// In en, this message translates to:
  /// **'Group texts can only be sent from {name}.'**
  String outcomeGroup(String name);

  /// No description provided for @outcomeNoService.
  ///
  /// In en, this message translates to:
  /// **'{name} has no signal.'**
  String outcomeNoService(String name);

  /// No description provided for @outcomeTimeout.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t confirm in time. Check the conversation on {name} before sending again.'**
  String outcomeTimeout(String name);

  /// No description provided for @outcomeFailed.
  ///
  /// In en, this message translates to:
  /// **'{name} couldn\'t send it. Send again, or send it from {name}.'**
  String outcomeFailed(String name);

  /// No description provided for @retrySend.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get retrySend;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @kindFailed.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get kindFailed;

  /// No description provided for @kindQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get kindQueued;

  /// No description provided for @kindOutbox.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get kindOutbox;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @contactCard.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactCard;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// Preview of the latest text when it is a photo or file: who sent it
  ///
  /// In en, this message translates to:
  /// **'{name}: Attachment'**
  String attachmentFrom(String name);

  /// Preview of the latest text on the Messages card: who sent it, then the start of the text
  ///
  /// In en, this message translates to:
  /// **'{name}: {text}'**
  String latestFrom(String name, String text);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @imageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the picture from {name}.'**
  String imageFailed(String name);

  /// No description provided for @rcsComputerNote.
  ///
  /// In en, this message translates to:
  /// **'RCS chats don\'t show here. They arrive with your phone\'s notifications, where you can answer them.'**
  String get rcsComputerNote;

  /// No description provided for @replyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyAction;

  /// Activity row for an unread text: who wrote, then the phone it arrived on
  ///
  /// In en, this message translates to:
  /// **'{sender} · {device}'**
  String activityTitle(String sender, String device);

  /// No description provided for @markReadAction.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markReadAction;

  /// No description provided for @replyFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply not sent'**
  String get replyFailedTitle;

  /// No description provided for @noticeTitleCount.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count, plural, other{{count} new}}'**
  String noticeTitleCount(String name, int count);

  /// No description provided for @noticeGroupBody.
  ///
  /// In en, this message translates to:
  /// **'{sender}: {text}'**
  String noticeGroupBody(String sender, String text);

  /// No description provided for @notifySetting.
  ///
  /// In en, this message translates to:
  /// **'Show new texts as notifications'**
  String get notifySetting;

  /// No description provided for @notifyDetail.
  ///
  /// In en, this message translates to:
  /// **'With Reply, unless the conversation is already open here.'**
  String get notifyDetail;

  /// No description provided for @forgetHistory.
  ///
  /// In en, this message translates to:
  /// **'Forget saved texts'**
  String get forgetHistory;

  /// No description provided for @forgetDetail.
  ///
  /// In en, this message translates to:
  /// **'Ferret keeps recent texts on this computer so they show while the phone is offline.'**
  String get forgetDetail;

  /// No description provided for @forgetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget saved texts?'**
  String get forgetConfirmTitle;

  /// No description provided for @forgetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the texts saved on this computer. Your phone keeps them all.'**
  String get forgetConfirmBody;

  /// No description provided for @forgetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forgetConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;
}

class _MessagesLocalizationsDelegate
    extends LocalizationsDelegate<MessagesLocalizations> {
  const _MessagesLocalizationsDelegate();

  @override
  Future<MessagesLocalizations> load(Locale locale) {
    return SynchronousFuture<MessagesLocalizations>(
      lookupMessagesLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_MessagesLocalizationsDelegate old) => false;
}

MessagesLocalizations lookupMessagesLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return MessagesLocalizationsEn();
  }

  throw FlutterError(
    'MessagesLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
