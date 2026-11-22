import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'iphone_localizations_en.dart';
import 'iphone_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of IphoneLocalizations
/// returned by `IphoneLocalizations.of(context)`.
///
/// Applications need to include `IphoneLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/iphone_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: IphoneLocalizations.localizationsDelegates,
///   supportedLocales: IphoneLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the IphoneLocalizations.supportedLocales
/// property.
abstract class IphoneLocalizations {
  IphoneLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static IphoneLocalizations of(BuildContext context) {
    return Localizations.of<IphoneLocalizations>(context, IphoneLocalizations)!;
  }

  static const LocalizationsDelegate<IphoneLocalizations> delegate =
      _IphoneLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'iPhone'**
  String get title;

  /// No description provided for @nowPlayingOn.
  ///
  /// In en, this message translates to:
  /// **'Now playing on {device}'**
  String nowPlayingOn(String device);

  /// No description provided for @pausedOn.
  ///
  /// In en, this message translates to:
  /// **'Paused on {device}'**
  String pausedOn(String device);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Media control: next track
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Media control: previous track
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @volumeUp.
  ///
  /// In en, this message translates to:
  /// **'Volume up'**
  String get volumeUp;

  /// No description provided for @volumeDown.
  ///
  /// In en, this message translates to:
  /// **'Volume down'**
  String get volumeDown;

  /// No description provided for @commandFailed.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer. Keep it near {here, select, macOS{this Mac} windows{this PC} other{this computer}}, then try again.'**
  String commandFailed(String device, String here);

  /// No description provided for @problemBluetoothOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off'**
  String get problemBluetoothOffTitle;

  /// No description provided for @problemBluetoothOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth on {here, select, macOS{this Mac} windows{this PC} other{this computer}} to get your iPhone\'s notifications and media here.'**
  String problemBluetoothOffBody(String here);

  /// No description provided for @problemUnauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ferret can\'t use Bluetooth'**
  String get problemUnauthorizedTitle;

  /// No description provided for @problemUnauthorizedBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth for Ferret in {here, select, macOS{this Mac\'s} windows{this PC\'s} other{{here, select, macOS{this Mac} windows{this PC} other{this computer}}\'s}} privacy settings, then try again.'**
  String problemUnauthorizedBody(String here);

  /// No description provided for @problemNoDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your iPhone'**
  String get problemNoDeviceTitle;

  /// No description provided for @problemNoDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Pair it with {here, select, macOS{this Mac} windows{this PC} other{this computer}}, then choose it in Ferret.'**
  String problemNoDeviceBody(String here);

  /// No description provided for @problemNotSharedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t sharing with {here, select, macOS{this Mac} windows{this PC} other{this computer}}'**
  String problemNotSharedTitle(String device, String here);

  /// No description provided for @problemNotSharedBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: Settings → Bluetooth, tap ⓘ next to {here, select, macOS{this Mac} windows{this PC} other{this computer}}, then turn on Share System Notifications. Not listed there? Pair it again.'**
  String problemNotSharedBody(String device, String here);

  /// No description provided for @yourIphone.
  ///
  /// In en, this message translates to:
  /// **'iPhone'**
  String get yourIphone;

  /// No description provided for @openBluetoothSettings.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth settings'**
  String get openBluetoothSettings;

  /// No description provided for @openFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the Bluetooth settings. Open them from your system settings.'**
  String get openFailed;

  /// No description provided for @setUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get setUp;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @settingsEnable.
  ///
  /// In en, this message translates to:
  /// **'Connect an iPhone'**
  String get settingsEnable;

  /// No description provided for @settingsEnableBody.
  ///
  /// In en, this message translates to:
  /// **'Shows its notifications and what it plays, over Bluetooth. Nothing to install on the iPhone.'**
  String get settingsEnableBody;

  /// No description provided for @worksTitle.
  ///
  /// In en, this message translates to:
  /// **'What works with an iPhone'**
  String get worksTitle;

  /// No description provided for @worksBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications as they arrive, with Clear, Answer and Decline. Play, pause, skip and volume for whatever the iPhone plays.'**
  String get worksBody;

  /// No description provided for @limitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get limitsTitle;

  /// No description provided for @limitsBody.
  ///
  /// In en, this message translates to:
  /// **'Reading and sending texts (SMS and iMessage) and taking calls on {here, select, macOS{this Mac} windows{this PC} other{this computer}}. Apple keeps files, clipboard and Handoff to its own devices.'**
  String limitsBody(String here);

  /// No description provided for @macNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Beta on a Mac'**
  String get macNoteTitle;

  /// No description provided for @macNote.
  ///
  /// In en, this message translates to:
  /// **'It only works while macOS itself is connected to the iPhone over Bluetooth, and macOS may keep the iPhone\'s notifications to itself.'**
  String get macNote;

  /// No description provided for @statusUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This computer has no Bluetooth LE, which the iPhone link needs.'**
  String get statusUnsupported;

  /// No description provided for @statusNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This build of Ferret isn\'t allowed to use Bluetooth.'**
  String get statusNotConfigured;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {device}…'**
  String statusConnecting(String device);

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to {device}'**
  String statusConnected(String device);

  /// No description provided for @statusOutOfReach.
  ///
  /// In en, this message translates to:
  /// **'{device} is out of reach. Ferret reconnects when it\'s back.'**
  String statusOutOfReach(String device);

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t talk to {device}. Trying again shortly.'**
  String statusFailed(String device);

  /// Settings row value when this computer can't use Bluetooth LE.
  ///
  /// In en, this message translates to:
  /// **'Not available on {here, select, macOS{this Mac} windows{this PC} other{this computer}}'**
  String summaryUnavailable(String here);

  /// Settings row value.
  ///
  /// In en, this message translates to:
  /// **'{device} is out of reach'**
  String summaryOutOfReach(String device);

  /// Settings row value.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t sharing'**
  String summaryNotShared(String device);

  /// No description provided for @notificationsNotShared.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t sharing its notifications. On {device}: Settings → Bluetooth, tap ⓘ next to {here, select, macOS{this Mac} windows{this PC} other{this computer}}, then turn on Share System Notifications.'**
  String notificationsNotShared(String device, String here);

  /// No description provided for @mediaNotShared.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t sharing what it plays with {here, select, macOS{this Mac} windows{this PC} other{this computer}}.'**
  String mediaNotShared(String device, String here);

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair your iPhone'**
  String get setupTitle;

  /// No description provided for @setupStepUnlock.
  ///
  /// In en, this message translates to:
  /// **'On the iPhone: unlock it and open Settings → Bluetooth. Keep that screen open.'**
  String get setupStepUnlock;

  /// No description provided for @setupStepPairWindows.
  ///
  /// In en, this message translates to:
  /// **'On this PC, open Bluetooth settings, choose Add device → Bluetooth and pick the iPhone. Confirm the code on both.'**
  String get setupStepPairWindows;

  /// No description provided for @setupStepPairMac.
  ///
  /// In en, this message translates to:
  /// **'Keep the iPhone signed in and near this Mac with Bluetooth on, so macOS connects to it.'**
  String get setupStepPairMac;

  /// No description provided for @setupStepPairLinux.
  ///
  /// In en, this message translates to:
  /// **'This computer now shows up on the iPhone under Other Devices. Tap it there, and confirm the code on both.'**
  String get setupStepPairLinux;

  /// No description provided for @setupStepAllow.
  ///
  /// In en, this message translates to:
  /// **'When the iPhone asks, allow it to show notifications on {here, select, macOS{this Mac} windows{this PC} other{this computer}}.'**
  String setupStepAllow(String here);

  /// No description provided for @setupStepChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose the iPhone below.'**
  String get setupStepChoose;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Paired devices'**
  String get devicesTitle;

  /// No description provided for @devicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No paired iPhone found yet.'**
  String get devicesEmpty;

  /// No description provided for @devicesRefresh.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get devicesRefresh;

  /// No description provided for @deviceUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get deviceUse;

  /// No description provided for @deviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get deviceConnected;

  /// No description provided for @deviceUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed device'**
  String get deviceUnnamed;

  /// No description provided for @forget.
  ///
  /// In en, this message translates to:
  /// **'Use another iPhone'**
  String get forget;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Show notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'New ones only. What was already on the iPhone stays there.'**
  String get settingsNotificationsBody;

  /// No description provided for @settingsMedia.
  ///
  /// In en, this message translates to:
  /// **'Media controls'**
  String get settingsMedia;

  /// No description provided for @settingsMediaBody.
  ///
  /// In en, this message translates to:
  /// **'A card with what the iPhone plays, and its controls.'**
  String get settingsMediaBody;

  /// No description provided for @settingsHidePreviews.
  ///
  /// In en, this message translates to:
  /// **'Hide what notifications say'**
  String get settingsHidePreviews;

  /// No description provided for @settingsHidePreviewsBody.
  ///
  /// In en, this message translates to:
  /// **'Show only which app it is, for when others can see your screen.'**
  String get settingsHidePreviewsBody;

  /// No description provided for @noticeTitle.
  ///
  /// In en, this message translates to:
  /// **'{app}: {title}'**
  String noticeTitle(String app, String title);

  /// No description provided for @noticeHidden.
  ///
  /// In en, this message translates to:
  /// **'New notification'**
  String get noticeHidden;

  /// No description provided for @noticeFromIphone.
  ///
  /// In en, this message translates to:
  /// **'iPhone'**
  String get noticeFromIphone;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get actionAnswer;

  /// No description provided for @actionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get actionDecline;

  /// No description provided for @actionCallBack.
  ///
  /// In en, this message translates to:
  /// **'Call back'**
  String get actionCallBack;

  /// No description provided for @actionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// No description provided for @actionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer'**
  String actionFailedTitle(String device);

  /// No description provided for @actionFailedBody.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t reach {device}. Keep it near {here, select, macOS{this Mac} windows{this PC} other{this computer}}, then try again.'**
  String actionFailedBody(String device, String here);
}

class _IphoneLocalizationsDelegate
    extends LocalizationsDelegate<IphoneLocalizations> {
  const _IphoneLocalizationsDelegate();

  @override
  Future<IphoneLocalizations> load(Locale locale) {
    return SynchronousFuture<IphoneLocalizations>(
      lookupIphoneLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_IphoneLocalizationsDelegate old) => false;
}

IphoneLocalizations lookupIphoneLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return IphoneLocalizationsEn();
    case 'vi':
      return IphoneLocalizationsVi();
  }

  throw FlutterError(
    'IphoneLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
