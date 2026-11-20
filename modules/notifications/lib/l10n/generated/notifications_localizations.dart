import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'notifications_localizations_en.dart';
import 'notifications_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of NotificationsLocalizations
/// returned by `NotificationsLocalizations.of(context)`.
///
/// Applications need to include `NotificationsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/notifications_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: NotificationsLocalizations.localizationsDelegates,
///   supportedLocales: NotificationsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the NotificationsLocalizations.supportedLocales
/// property.
abstract class NotificationsLocalizations {
  NotificationsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static NotificationsLocalizations of(BuildContext context) {
    return Localizations.of<NotificationsLocalizations>(
      context,
      NotificationsLocalizations,
    )!;
  }

  static const LocalizationsDelegate<NotificationsLocalizations> delegate =
      _NotificationsLocalizationsDelegate();

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
  /// **'Notifications'**
  String get title;

  /// No description provided for @explainer.
  ///
  /// In en, this message translates to:
  /// **'Shows {here, select, tablet{this tablet\'s} other{this phone\'s}} notifications on your computer. Every app comes through, and you can mute the ones you don\'t want.'**
  String explainer(String here);

  /// No description provided for @offerDescription.
  ///
  /// In en, this message translates to:
  /// **'See {here, select, tablet{this tablet\'s} other{this phone\'s}} notifications on your computer.'**
  String offerDescription(String here);

  /// No description provided for @explainerDetail.
  ///
  /// In en, this message translates to:
  /// **'Only new notifications. Nothing leaves your network.'**
  String get explainerDetail;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// Stops sending this phone's notifications to computers (not screen mirroring)
  ///
  /// In en, this message translates to:
  /// **'Turn off mirroring'**
  String get turnOff;

  /// No description provided for @accessOn.
  ///
  /// In en, this message translates to:
  /// **'Notification access is on'**
  String get accessOn;

  /// No description provided for @accessOff.
  ///
  /// In en, this message translates to:
  /// **'Notification access is off'**
  String get accessOff;

  /// No description provided for @accessStillOff.
  ///
  /// In en, this message translates to:
  /// **'Still off. Turn on Ferret on the Notification access screen, then come back.'**
  String get accessStillOff;

  /// No description provided for @accessHowTo.
  ///
  /// In en, this message translates to:
  /// **'On the next screen, turn on Ferret, then come back here.'**
  String get accessHowTo;

  /// No description provided for @openAccessSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification access'**
  String get openAccessSettings;

  /// No description provided for @openSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Settings. Open Settings → Notifications → Notification access yourself.'**
  String get openSettingsFailed;

  /// No description provided for @restrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Android blocked this setting'**
  String get restrictedTitle;

  /// No description provided for @restrictedBody.
  ///
  /// In en, this message translates to:
  /// **'Android blocks it for apps installed outside an app store. Allow it once:'**
  String get restrictedBody;

  /// No description provided for @restrictedStepOne.
  ///
  /// In en, this message translates to:
  /// **'Open App info.'**
  String get restrictedStepOne;

  /// No description provided for @restrictedStepTwo.
  ///
  /// In en, this message translates to:
  /// **'Tap ⋮ in the top corner, then Allow restricted settings.'**
  String get restrictedStepTwo;

  /// No description provided for @restrictedStepThree.
  ///
  /// In en, this message translates to:
  /// **'Come back and open notification access again.'**
  String get restrictedStepThree;

  /// No description provided for @openAppInfo.
  ///
  /// In en, this message translates to:
  /// **'Open App info'**
  String get openAppInfo;

  /// No description provided for @skipWhileUsing.
  ///
  /// In en, this message translates to:
  /// **'Pause while I\'m using the phone'**
  String get skipWhileUsing;

  /// No description provided for @skipWhileUsingDetail.
  ///
  /// In en, this message translates to:
  /// **'When the screen is on and unlocked, you already see them there.'**
  String get skipWhileUsingDetail;

  /// No description provided for @chooseApps.
  ///
  /// In en, this message translates to:
  /// **'Choose apps'**
  String get chooseApps;

  /// Which apps a phone mirrors: every app. Shown on the device page, in Settings and on the Choose apps button.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get appsAll;

  /// Which apps a phone mirrors: every app but the muted ones.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All apps} =1{All apps except 1} other{All apps except {count}}}'**
  String appsAllExcept(int count);

  /// Which apps a phone mirrors: only the picked ones.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No apps picked} =1{1 app} other{{count} apps}}'**
  String appsOnly(int count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All apps'**
  String get filterAll;

  /// No description provided for @filterAllDetail.
  ///
  /// In en, this message translates to:
  /// **'Every app\'s notifications come to your computer.'**
  String get filterAllDetail;

  /// No description provided for @filterAllExcept.
  ///
  /// In en, this message translates to:
  /// **'All apps except…'**
  String get filterAllExcept;

  /// No description provided for @filterAllExceptDetail.
  ///
  /// In en, this message translates to:
  /// **'Mute a few noisy apps.'**
  String get filterAllExceptDetail;

  /// No description provided for @filterOnly.
  ///
  /// In en, this message translates to:
  /// **'Only these apps…'**
  String get filterOnly;

  /// No description provided for @filterOnlyDetail.
  ///
  /// In en, this message translates to:
  /// **'Pick the few apps you want.'**
  String get filterOnlyDetail;

  /// No description provided for @filterBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Ferret\'s own notifications, music controls and silent or ongoing ones always stay on the phone.'**
  String get filterBuiltIn;

  /// No description provided for @appPickerMuteHint.
  ///
  /// In en, this message translates to:
  /// **'Switch off the apps you don\'t want on your computer.'**
  String get appPickerMuteHint;

  /// No description provided for @appPickerOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Switch on the apps you want on your computer.'**
  String get appPickerOnlyHint;

  /// No description provided for @appPickerApps.
  ///
  /// In en, this message translates to:
  /// **'Apps, most recent first'**
  String get appPickerApps;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectNone.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get selectNone;

  /// No description provided for @appPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose apps'**
  String get appPickerTitle;

  /// No description provided for @appPickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get appPickerSearch;

  /// No description provided for @appPickerLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting the apps…'**
  String get appPickerLoading;

  /// No description provided for @appPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No apps match.'**
  String get appPickerEmpty;

  /// No description provided for @appPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get the apps from {device}. Make sure it\'s connected.'**
  String appPickerFailed(String device);

  /// No description provided for @appPickerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that change on {device}.'**
  String appPickerSaveFailed(String device);

  /// Stands in for a device name in the middle of other sentences
  ///
  /// In en, this message translates to:
  /// **'{here, select, tablet{this tablet} other{this phone}}'**
  String thisPhone(String here);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'Connect your Android phone to see its notifications here.'**
  String get noPhone;

  /// Status of a phone that mirrors here; apps is appsAll, appsAllExcept or appsOnly.
  ///
  /// In en, this message translates to:
  /// **'On · {apps}'**
  String phoneMirroring(String apps);

  /// Device page, next to Notifications.
  ///
  /// In en, this message translates to:
  /// **'Off on {device}'**
  String phoneMirroringOff(String device);

  /// Device page, next to Notifications.
  ///
  /// In en, this message translates to:
  /// **'Android turned off Ferret\'s access'**
  String get phoneAccessOff;

  /// No description provided for @phoneChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get phoneChecking;

  /// Device page, next to Notifications.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer'**
  String phoneUnreachable(String device);

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet. New ones from your phone show up here.'**
  String get homeEmpty;

  /// No description provided for @homeEmptyFrom.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet. New ones from {device} show up here.'**
  String homeEmptyFrom(String device);

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// Dismisses the notification on the phone too
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'offline'**
  String get offline;

  /// No description provided for @whileAway.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification while away} other{{count} notifications while away}}'**
  String whileAway(int count);

  /// No description provided for @whileAwayFrom.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification while away} other{{count} notifications while away}}, from {apps}'**
  String whileAwayFrom(int count, String apps);

  /// No description provided for @replyFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply not sent'**
  String get replyFailedTitle;

  /// No description provided for @replyFailedBody.
  ///
  /// In en, this message translates to:
  /// **'{device} is offline or the notification is gone. Reply on {device}.'**
  String replyFailedBody(String device);

  /// No description provided for @setUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get setUp;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @phoneHomePaused.
  ///
  /// In en, this message translates to:
  /// **'Notification access is off on {here, select, tablet{this tablet} other{this phone}}, so your computer gets no notifications.'**
  String phoneHomePaused(String here);

  /// No description provided for @homeTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on Notifications on {device} to see its notifications here.'**
  String homeTurnOn(String device);

  /// No description provided for @homeOffline.
  ///
  /// In en, this message translates to:
  /// **'{device} is offline. Notifications show here when it\'s back.'**
  String homeOffline(String device);

  /// No description provided for @homeAccessOff.
  ///
  /// In en, this message translates to:
  /// **'Android turned off Ferret\'s access on {device}. On {device}: open Ferret and tap Fix.'**
  String homeAccessOff(String device);

  /// No description provided for @homeUnreachable.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer. On {device}: open Ferret.'**
  String homeUnreachable(String device);

  /// No description provided for @howTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on Notifications on {device}'**
  String howTitle(String device);

  /// No description provided for @howBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: Ferret → Do more → Notifications. Ferret asks for notification access, then every app\'s notifications show here.'**
  String howBody(String device);

  /// No description provided for @how.
  ///
  /// In en, this message translates to:
  /// **'How?'**
  String get how;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get ok;

  /// Settings row value on the phone: Notifications are on but Android doesn't let Ferret read them.
  ///
  /// In en, this message translates to:
  /// **'Needs access'**
  String get settingsNeedsAccess;

  /// Settings row value on a computer.
  ///
  /// In en, this message translates to:
  /// **'Needs access on {device}'**
  String settingsNeedsAccessOn(String device);

  /// No description provided for @settingsPerPhone.
  ///
  /// In en, this message translates to:
  /// **'Every app comes through unless you change it. To mute apps or stop showing a phone here, open the phone from Home.'**
  String get settingsPerPhone;

  /// Switch on a phone's page, under "<phone> may".
  ///
  /// In en, this message translates to:
  /// **'Show its notifications here'**
  String get permissionShow;

  /// Switch on a phone's page, under "<phone> may", after "Show its notifications here".
  ///
  /// In en, this message translates to:
  /// **'Hold them back while it\'s in use'**
  String get permissionHold;

  /// No description provided for @actionChooseApps.
  ///
  /// In en, this message translates to:
  /// **'Choose notification apps'**
  String get actionChooseApps;

  /// Device page, next to Notifications, when this computer doesn't show that phone's notifications.
  ///
  /// In en, this message translates to:
  /// **'Turned off here'**
  String get healthHiddenHere;

  /// No description provided for @healthHiddenHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn on \"Show its notifications here\" below.'**
  String get healthHiddenHelp;

  /// No description provided for @healthAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret and tap Fix.'**
  String healthAccessHelp(String device);

  /// No description provided for @healthOffThisPhone.
  ///
  /// In en, this message translates to:
  /// **'Off on {here, select, tablet{this tablet} other{this phone}}'**
  String healthOffThisPhone(String here);

  /// No description provided for @healthOffThisPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'On {here, select, tablet{this tablet} other{this phone}}: Settings → To your computer → Notifications.'**
  String healthOffThisPhoneHelp(String here);

  /// No description provided for @activityOne.
  ///
  /// In en, this message translates to:
  /// **'{app}: {title}'**
  String activityOne(String app, String title);

  /// No description provided for @activityCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification from {device}} other{{count} notifications from {device}}}'**
  String activityCount(int count, String device);

  /// Shown instead of a notification when its previews are hidden on this computer
  ///
  /// In en, this message translates to:
  /// **'New notification from {device}'**
  String privateCover(String device);

  /// No description provided for @hideCodes.
  ///
  /// In en, this message translates to:
  /// **'Hide one-time codes'**
  String get hideCodes;

  /// No description provided for @hideCodesDetail.
  ///
  /// In en, this message translates to:
  /// **'Sign-in, bank and delivery codes stay on {here, select, tablet{this tablet} other{this phone}}. Computers show the app and \"Code hidden\".'**
  String hideCodesDetail(String here);

  /// No description provided for @codeHidden.
  ///
  /// In en, this message translates to:
  /// **'Code hidden. Open it on the phone.'**
  String get codeHidden;
}

class _NotificationsLocalizationsDelegate
    extends LocalizationsDelegate<NotificationsLocalizations> {
  const _NotificationsLocalizationsDelegate();

  @override
  Future<NotificationsLocalizations> load(Locale locale) {
    return SynchronousFuture<NotificationsLocalizations>(
      lookupNotificationsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_NotificationsLocalizationsDelegate old) => false;
}

NotificationsLocalizations lookupNotificationsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return NotificationsLocalizationsEn();
    case 'vi':
      return NotificationsLocalizationsVi();
  }

  throw FlutterError(
    'NotificationsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
