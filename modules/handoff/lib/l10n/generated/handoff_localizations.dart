import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'handoff_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of HandoffLocalizations
/// returned by `HandoffLocalizations.of(context)`.
///
/// Applications need to include `HandoffLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/handoff_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: HandoffLocalizations.localizationsDelegates,
///   supportedLocales: HandoffLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the HandoffLocalizations.supportedLocales
/// property.
abstract class HandoffLocalizations {
  HandoffLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static HandoffLocalizations of(BuildContext context) {
    return Localizations.of<HandoffLocalizations>(
      context,
      HandoffLocalizations,
    )!;
  }

  static const LocalizationsDelegate<HandoffLocalizations> delegate =
      _HandoffLocalizationsDelegate();

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
  /// **'Continue'**
  String get title;

  /// No description provided for @cardTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cardTitle;

  /// No description provided for @continueFrom.
  ///
  /// In en, this message translates to:
  /// **'Continue “{title}” from {device}'**
  String continueFrom(String title, String device);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'This device can\'t open that. It may need an app that isn\'t installed here.'**
  String get openFailed;

  /// No description provided for @openDeferred.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret to continue it.'**
  String get openDeferred;

  /// No description provided for @actionSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send a link…'**
  String get actionSendLink;

  /// No description provided for @actionSendCurrentPage.
  ///
  /// In en, this message translates to:
  /// **'Send current page'**
  String get actionSendCurrentPage;

  /// No description provided for @sendLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to {device}'**
  String sendLinkTitle(String device);

  /// No description provided for @sendLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link or text'**
  String get sendLinkLabel;

  /// No description provided for @sendLinkHint.
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get sendLinkHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to send. Paste a link or some text.'**
  String get sendEmpty;

  /// No description provided for @sendOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened on {device}'**
  String sendOpened(String device);

  /// No description provided for @sendSuggested.
  ///
  /// In en, this message translates to:
  /// **'On {device}: tap the notification to open it.'**
  String sendSuggested(String device);

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t open it. It may need an app that isn\'t installed there.'**
  String sendFailed(String device);

  /// No description provided for @sendUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach {device}. Check that it\'s on and on the same Wi-Fi.'**
  String sendUnreachable(String device);

  /// No description provided for @currentPageNone.
  ///
  /// In en, this message translates to:
  /// **'No browser page found. Open a page in Safari or a Chromium browser, then try again.'**
  String get currentPageNone;

  /// No description provided for @currentPageDenied.
  ///
  /// In en, this message translates to:
  /// **'macOS blocked Ferret from reading your browser. Allow it in System Settings, Privacy & Security, Automation.'**
  String get currentPageDenied;

  /// No description provided for @currentPageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the browser page. Try again, or send the link with “Send a link…”.'**
  String get currentPageFailed;

  /// No description provided for @settingsPassive.
  ///
  /// In en, this message translates to:
  /// **'Suggest what I\'m doing'**
  String get settingsPassive;

  /// No description provided for @settingsPassiveBody.
  ///
  /// In en, this message translates to:
  /// **'Your other devices quietly offer to continue the page you\'re on. Suggestions go away after 5 minutes.'**
  String get settingsPassiveBody;

  /// No description provided for @settingsOpenAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Open sent links right away'**
  String get settingsOpenAutomatically;

  /// No description provided for @settingsOpenAutomaticallyBody.
  ///
  /// In en, this message translates to:
  /// **'When off, things sent here wait in a notification until you open them.'**
  String get settingsOpenAutomaticallyBody;

  /// No description provided for @settingsBrowserTab.
  ///
  /// In en, this message translates to:
  /// **'Read the current browser page'**
  String get settingsBrowserTab;

  /// No description provided for @settingsBrowserTabBody.
  ///
  /// In en, this message translates to:
  /// **'Adds “Send current page”, and suggests the page you leave. macOS asks once per browser.'**
  String get settingsBrowserTabBody;

  /// No description provided for @settingsAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue from any app'**
  String get settingsAssistantTitle;

  /// No description provided for @settingsAssistantBody.
  ///
  /// In en, this message translates to:
  /// **'Make Ferret your digital assistant, then long-press Home (or swipe up from a bottom corner) on any screen to send it to another device. Turn on “Use text from screen” on the same settings page.'**
  String get settingsAssistantBody;

  /// No description provided for @settingsAssistantOn.
  ///
  /// In en, this message translates to:
  /// **'Ferret is your assistant'**
  String get settingsAssistantOn;

  /// No description provided for @settingsAssistantOff.
  ///
  /// In en, this message translates to:
  /// **'Ferret isn\'t your assistant yet'**
  String get settingsAssistantOff;

  /// No description provided for @settingsAssistantOpen.
  ///
  /// In en, this message translates to:
  /// **'Open assistant settings'**
  String get settingsAssistantOpen;

  /// No description provided for @settingsShareHint.
  ///
  /// In en, this message translates to:
  /// **'You can also share any link to “Continue on…”.'**
  String get settingsShareHint;

  /// No description provided for @summaryPassive.
  ///
  /// In en, this message translates to:
  /// **'Offers the page you\'re on'**
  String get summaryPassive;

  /// No description provided for @summarySendsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only what you send'**
  String get summarySendsOnly;

  /// No description provided for @summaryBrowserOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get summaryBrowserOff;

  /// No description provided for @summaryNoBrowser.
  ///
  /// In en, this message translates to:
  /// **'No browser yet'**
  String get summaryNoBrowser;

  /// No description provided for @healthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Needs a Ferret update on {name}'**
  String healthUnsupported(String name);

  /// No description provided for @healthOpensRightAway.
  ///
  /// In en, this message translates to:
  /// **'Links from {name} open right away'**
  String healthOpensRightAway(String name);

  /// No description provided for @healthWaits.
  ///
  /// In en, this message translates to:
  /// **'Links from {name} wait in a notification'**
  String healthWaits(String name);

  /// No description provided for @healthLastSendFailed.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t get the last link you sent'**
  String healthLastSendFailed(String name);

  /// No description provided for @healthLastSendFailedHelp.
  ///
  /// In en, this message translates to:
  /// **'On {name}: open Ferret, then send the link again.'**
  String healthLastSendFailedHelp(String name);

  /// No description provided for @noticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue “{title}”'**
  String noticeTitle(String title);

  /// No description provided for @noticeFrom.
  ///
  /// In en, this message translates to:
  /// **'From {device}'**
  String noticeFrom(String device);

  /// No description provided for @noticeTextCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied text from {device}'**
  String noticeTextCopied(String device);

  /// No description provided for @noticeSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {device}'**
  String noticeSent(String device);

  /// No description provided for @noticeNotSent.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send to {device}'**
  String noticeNotSent(String device);

  /// No description provided for @noticeNotSentBody.
  ///
  /// In en, this message translates to:
  /// **'Check that it\'s on and on the same Wi-Fi, then share it again.'**
  String get noticeNotSentBody;

  /// No description provided for @noticeNothingToSend.
  ///
  /// In en, this message translates to:
  /// **'There was nothing to continue in what you shared.'**
  String get noticeNothingToSend;

  /// No description provided for @pickDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue on'**
  String get pickDeviceTitle;

  /// No description provided for @pickDeviceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No device is connected right now. Open Ferret on your other device, on the same Wi-Fi.'**
  String get pickDeviceEmpty;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @browserPairTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow {browser} to use Ferret?'**
  String browserPairTitle(String browser);

  /// No description provided for @browserPairBody.
  ///
  /// In en, this message translates to:
  /// **'Check that your browser shows {code}. It can then send tabs to your devices and open the pages they send here.'**
  String browserPairBody(String code);

  /// No description provided for @browserPairAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get browserPairAllow;

  /// No description provided for @browserPairDeny.
  ///
  /// In en, this message translates to:
  /// **'Don\'t allow'**
  String get browserPairDeny;

  /// No description provided for @noticeBrowserPairBody.
  ///
  /// In en, this message translates to:
  /// **'Code {code}. Open Ferret to allow it.'**
  String noticeBrowserPairBody(String code);

  /// No description provided for @settingsBrowserBridge.
  ///
  /// In en, this message translates to:
  /// **'Browser extension'**
  String get settingsBrowserBridge;

  /// No description provided for @settingsBrowserBridgeBody.
  ///
  /// In en, this message translates to:
  /// **'Lets the Ferret extension in Chrome, Edge, Brave or Firefox send tabs and open pages from your devices. It only listens on this computer.'**
  String get settingsBrowserBridgeBody;

  /// No description provided for @browserBridgeListening.
  ///
  /// In en, this message translates to:
  /// **'To add another browser, pair from the extension\'s settings page.'**
  String get browserBridgeListening;

  /// No description provided for @browserBridgeFailed.
  ///
  /// In en, this message translates to:
  /// **'Ferret couldn\'t start the browser connection. Another copy of Ferret may be running: quit it, then try again.'**
  String get browserBridgeFailed;

  /// No description provided for @browserBridgeRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get browserBridgeRetry;

  /// No description provided for @browserClientsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No browser yet. Install the extension, open its settings and choose “Pair with Ferret”.'**
  String get browserClientsEmpty;

  /// No description provided for @browserClientConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get browserClientConnected;

  /// No description provided for @browserClientOffline.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get browserClientOffline;

  /// No description provided for @browserClientRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get browserClientRemove;

  /// No description provided for @continueUntitledFrom.
  ///
  /// In en, this message translates to:
  /// **'Continue from {device}'**
  String continueUntitledFrom(String device);
}

class _HandoffLocalizationsDelegate
    extends LocalizationsDelegate<HandoffLocalizations> {
  const _HandoffLocalizationsDelegate();

  @override
  Future<HandoffLocalizations> load(Locale locale) {
    return SynchronousFuture<HandoffLocalizations>(
      lookupHandoffLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_HandoffLocalizationsDelegate old) => false;
}

HandoffLocalizations lookupHandoffLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return HandoffLocalizationsEn();
  }

  throw FlutterError(
    'HandoffLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
