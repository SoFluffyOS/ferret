import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'power_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PowerLocalizations
/// returned by `PowerLocalizations.of(context)`.
///
/// Applications need to include `PowerLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/power_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PowerLocalizations.localizationsDelegates,
///   supportedLocales: PowerLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the PowerLocalizations.supportedLocales
/// property.
abstract class PowerLocalizations {
  PowerLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PowerLocalizations of(BuildContext context) {
    return Localizations.of<PowerLocalizations>(context, PowerLocalizations)!;
  }

  static const LocalizationsDelegate<PowerLocalizations> delegate =
      _PowerLocalizationsDelegate();

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
  /// **'Power-ups'**
  String get title;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @settingsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Power-ups are extra abilities for Android phones. There\'s nothing to set up on this device.'**
  String get settingsUnsupported;

  /// No description provided for @settingsSummaryStandard.
  ///
  /// In en, this message translates to:
  /// **'Ferret runs as a normal app. With Shizuku or root it can also send your clipboard in the background.'**
  String get settingsSummaryStandard;

  /// No description provided for @settingsSummaryShizuku.
  ///
  /// In en, this message translates to:
  /// **'Shizuku is on. Ferret can send your clipboard in the background.'**
  String get settingsSummaryShizuku;

  /// No description provided for @settingsSummaryRoot.
  ///
  /// In en, this message translates to:
  /// **'Root is on. Ferret can send your clipboard in the background, also after a restart.'**
  String get settingsSummaryRoot;

  /// No description provided for @settingsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Power-ups'**
  String get settingsOpen;

  /// No description provided for @ladderTitle.
  ///
  /// In en, this message translates to:
  /// **'What this phone lets Ferret do'**
  String get ladderTitle;

  /// No description provided for @rungBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get rungBasic;

  /// No description provided for @rungNotifications.
  ///
  /// In en, this message translates to:
  /// **'+ Notifications'**
  String get rungNotifications;

  /// No description provided for @rungMessagesAndCalls.
  ///
  /// In en, this message translates to:
  /// **'+ Messages & calls'**
  String get rungMessagesAndCalls;

  /// No description provided for @rungShizuku.
  ///
  /// In en, this message translates to:
  /// **'+ Shizuku'**
  String get rungShizuku;

  /// No description provided for @rungRoot.
  ///
  /// In en, this message translates to:
  /// **'+ Root'**
  String get rungRoot;

  /// No description provided for @rungOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get rungOn;

  /// No description provided for @rungOff.
  ///
  /// In en, this message translates to:
  /// **'Not on yet'**
  String get rungOff;

  /// No description provided for @perkFiles.
  ///
  /// In en, this message translates to:
  /// **'Send and receive files'**
  String get perkFiles;

  /// No description provided for @perkClipboardTap.
  ///
  /// In en, this message translates to:
  /// **'Send your clipboard with a tap'**
  String get perkClipboardTap;

  /// No description provided for @perkHandoff.
  ///
  /// In en, this message translates to:
  /// **'Continue a page on another device'**
  String get perkHandoff;

  /// No description provided for @perkMedia.
  ///
  /// In en, this message translates to:
  /// **'Control what\'s playing'**
  String get perkMedia;

  /// No description provided for @perkFind.
  ///
  /// In en, this message translates to:
  /// **'Ring a lost device'**
  String get perkFind;

  /// No description provided for @perkNotifications.
  ///
  /// In en, this message translates to:
  /// **'See this phone\'s notifications on your other devices'**
  String get perkNotifications;

  /// No description provided for @perkReplies.
  ///
  /// In en, this message translates to:
  /// **'Reply to them and dismiss them from there'**
  String get perkReplies;

  /// No description provided for @perkMessages.
  ///
  /// In en, this message translates to:
  /// **'Read and answer text messages from your computer'**
  String get perkMessages;

  /// No description provided for @perkCalls.
  ///
  /// In en, this message translates to:
  /// **'See who\'s calling, then answer or decline'**
  String get perkCalls;

  /// No description provided for @perkClipboardBackground.
  ///
  /// In en, this message translates to:
  /// **'Send what you copy on its own, also in the background'**
  String get perkClipboardBackground;

  /// No description provided for @perkOneTapSetup.
  ///
  /// In en, this message translates to:
  /// **'Turn on notification access and background running with one tap'**
  String get perkOneTapSetup;

  /// No description provided for @perkSameAsShizuku.
  ///
  /// In en, this message translates to:
  /// **'Everything Shizuku adds'**
  String get perkSameAsShizuku;

  /// No description provided for @perkSurvivesRestart.
  ///
  /// In en, this message translates to:
  /// **'Keeps working after the phone restarts'**
  String get perkSurvivesRestart;

  /// No description provided for @notificationsOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification access'**
  String get notificationsOpenSettings;

  /// No description provided for @notificationsTurnOnNow.
  ///
  /// In en, this message translates to:
  /// **'Turn on now'**
  String get notificationsTurnOnNow;

  /// No description provided for @notificationsRestricted.
  ///
  /// In en, this message translates to:
  /// **'If Android says the setting is restricted, open App info, tap the three dots and choose Allow restricted settings. Then try again.'**
  String get notificationsRestricted;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get appInfo;

  /// No description provided for @messagesHint.
  ///
  /// In en, this message translates to:
  /// **'Ferret asks for these when you turn on Messages or Calls. Said no by mistake? Change it in App info.'**
  String get messagesHint;

  /// No description provided for @shizukuTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up Shizuku'**
  String get shizukuTitle;

  /// No description provided for @shizukuIntro.
  ///
  /// In en, this message translates to:
  /// **'Shizuku is a free, open-source app. It lets Ferret do a few things Android keeps for the system, without rooting your phone.'**
  String get shizukuIntro;

  /// No description provided for @stepInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Install Shizuku'**
  String get stepInstallTitle;

  /// No description provided for @stepInstallBody.
  ///
  /// In en, this message translates to:
  /// **'Get it from its website. It\'s on F-Droid too.'**
  String get stepInstallBody;

  /// No description provided for @stepInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Get Shizuku'**
  String get stepInstallButton;

  /// No description provided for @stepStartTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Start Shizuku'**
  String get stepStartTitle;

  /// No description provided for @stepStartBody.
  ///
  /// In en, this message translates to:
  /// **'Open Shizuku and follow its Start steps, then come back here. Ferret checks again when you return.'**
  String get stepStartBody;

  /// No description provided for @stepStartButton.
  ///
  /// In en, this message translates to:
  /// **'Open Shizuku'**
  String get stepStartButton;

  /// No description provided for @stepAllowTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Allow Ferret'**
  String get stepAllowTitle;

  /// No description provided for @stepAllowBody.
  ///
  /// In en, this message translates to:
  /// **'Shizuku asks whether Ferret may use it. Choose Allow all the time.'**
  String get stepAllowBody;

  /// No description provided for @stepAllowButton.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get stepAllowButton;

  /// No description provided for @shizukuOn.
  ///
  /// In en, this message translates to:
  /// **'Shizuku is on.'**
  String get shizukuOn;

  /// No description provided for @shizukuOnBody.
  ///
  /// In en, this message translates to:
  /// **'Next: turn on Send in the background in the Clipboard settings. Shizuku stops when the phone restarts; start it again from its app.'**
  String get shizukuOnBody;

  /// No description provided for @stopUsingShizuku.
  ///
  /// In en, this message translates to:
  /// **'Stop using Shizuku'**
  String get stopUsingShizuku;

  /// No description provided for @noticeShizukuRefused.
  ///
  /// In en, this message translates to:
  /// **'Shizuku said no. Open Shizuku, allow Ferret in its list of apps, then try again.'**
  String get noticeShizukuRefused;

  /// No description provided for @noticeShizukuNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Shizuku. Check that it\'s installed.'**
  String get noticeShizukuNotOpened;

  /// No description provided for @noticeLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the browser. Search for Shizuku on F-Droid or GitHub.'**
  String get noticeLinkFailed;

  /// No description provided for @noticeGrantFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Try again, or change it in the system settings.'**
  String get noticeGrantFailed;

  /// No description provided for @noticeRootRefused.
  ///
  /// In en, this message translates to:
  /// **'Root access was denied. Allow Ferret in your root manager, then try again.'**
  String get noticeRootRefused;

  /// No description provided for @noticeSettingsNotOpened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the system settings.'**
  String get noticeSettingsNotOpened;

  /// No description provided for @batteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep Ferret running in the background'**
  String get batteryTitle;

  /// No description provided for @batteryBody.
  ///
  /// In en, this message translates to:
  /// **'Stops Android from putting Ferret to sleep, so your devices stay connected.'**
  String get batteryBody;

  /// No description provided for @batteryOn.
  ///
  /// In en, this message translates to:
  /// **'Ferret may run in the background.'**
  String get batteryOn;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @rootTitle.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get rootTitle;

  /// No description provided for @rootNotFound.
  ///
  /// In en, this message translates to:
  /// **'This phone isn\'t rooted, and it doesn\'t need to be: Shizuku adds the same features.'**
  String get rootNotFound;

  /// No description provided for @rootFound.
  ///
  /// In en, this message translates to:
  /// **'Root found on this phone.'**
  String get rootFound;

  /// No description provided for @rootFoundWith.
  ///
  /// In en, this message translates to:
  /// **'Root found on this phone ({manager}).'**
  String rootFoundWith(String manager);

  /// No description provided for @rootWarning.
  ///
  /// In en, this message translates to:
  /// **'Root gives an app full control of your phone. Turn this on only if you rooted the phone yourself. Ferret uses root for what\'s listed above and nothing else, and only while this is on.'**
  String get rootWarning;

  /// No description provided for @useRoot.
  ///
  /// In en, this message translates to:
  /// **'Use root'**
  String get useRoot;

  /// No description provided for @rootPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Your root manager will ask you to confirm.'**
  String get rootPromptHint;

  /// No description provided for @rootOn.
  ///
  /// In en, this message translates to:
  /// **'Root is on.'**
  String get rootOn;

  /// No description provided for @stopUsingRoot.
  ///
  /// In en, this message translates to:
  /// **'Stop using root'**
  String get stopUsingRoot;

  /// No description provided for @cardStartShizuku.
  ///
  /// In en, this message translates to:
  /// **'Start Shizuku and Ferret sends what you copy on its own.'**
  String get cardStartShizuku;

  /// No description provided for @cardAllowShizuku.
  ///
  /// In en, this message translates to:
  /// **'Allow Shizuku and Ferret sends what you copy on its own.'**
  String get cardAllowShizuku;

  /// No description provided for @cardShizukuStopped.
  ///
  /// In en, this message translates to:
  /// **'Shizuku stopped, so background clipboard is paused. It stops whenever the phone restarts. Start it again.'**
  String get cardShizukuStopped;

  /// No description provided for @cardShizukuRevoked.
  ///
  /// In en, this message translates to:
  /// **'Shizuku no longer allows Ferret, so background clipboard is paused.'**
  String get cardShizukuRevoked;

  /// No description provided for @cardUseRoot.
  ///
  /// In en, this message translates to:
  /// **'Use root and Ferret sends what you copy on its own.'**
  String get cardUseRoot;

  /// No description provided for @cardRootLost.
  ///
  /// In en, this message translates to:
  /// **'Root access was taken away, so background clipboard is paused.'**
  String get cardRootLost;

  /// No description provided for @cardSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get cardSetUp;

  /// No description provided for @cardAskAgain.
  ///
  /// In en, this message translates to:
  /// **'Ask again'**
  String get cardAskAgain;
}

class _PowerLocalizationsDelegate
    extends LocalizationsDelegate<PowerLocalizations> {
  const _PowerLocalizationsDelegate();

  @override
  Future<PowerLocalizations> load(Locale locale) {
    return SynchronousFuture<PowerLocalizations>(
      lookupPowerLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_PowerLocalizationsDelegate old) => false;
}

PowerLocalizations lookupPowerLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return PowerLocalizationsEn();
  }

  throw FlutterError(
    'PowerLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
