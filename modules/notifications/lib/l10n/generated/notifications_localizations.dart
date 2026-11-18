import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'notifications_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get title;

  /// No description provided for @explainer.
  ///
  /// In en, this message translates to:
  /// **'Shows your phone\'s notifications on your computer. You pick which apps.'**
  String get explainer;

  /// No description provided for @offerDescription.
  ///
  /// In en, this message translates to:
  /// **'See your phone\'s notifications on your computer.'**
  String get offerDescription;

  /// No description provided for @explainerDetail.
  ///
  /// In en, this message translates to:
  /// **'Only new notifications from the apps you pick. Nothing leaves your network.'**
  String get explainerDetail;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @turnOff.
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

  /// No description provided for @appCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No apps picked} =1{1 app picked} other{{count} apps picked}}'**
  String appCount(int count);

  /// No description provided for @appPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps to mirror'**
  String get appPickerTitle;

  /// No description provided for @appPickerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get appPickerSearch;

  /// No description provided for @appPickerMessaging.
  ///
  /// In en, this message translates to:
  /// **'Messaging apps'**
  String get appPickerMessaging;

  /// No description provided for @appPickerOther.
  ///
  /// In en, this message translates to:
  /// **'Other apps'**
  String get appPickerOther;

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

  /// No description provided for @thisPhone.
  ///
  /// In en, this message translates to:
  /// **'this phone'**
  String get thisPhone;

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

  /// No description provided for @phoneMirroring.
  ///
  /// In en, this message translates to:
  /// **'Mirroring {count, plural, =0{no apps} =1{1 app} other{{count} apps}}'**
  String phoneMirroring(int count);

  /// No description provided for @phoneMirroringOff.
  ///
  /// In en, this message translates to:
  /// **'Mirroring is off. Turn it on in Ferret on the phone.'**
  String get phoneMirroringOff;

  /// No description provided for @phoneAccessOff.
  ///
  /// In en, this message translates to:
  /// **'Notification access is off. Open Ferret on the phone to fix it.'**
  String get phoneAccessOff;

  /// No description provided for @phoneChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get phoneChecking;

  /// No description provided for @phoneUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach notifications on this phone.'**
  String get phoneUnreachable;

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet. New ones from your phone show up here.'**
  String get homeEmpty;

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

  /// No description provided for @dismiss.
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
  /// **'{device} is offline or the notification is gone. Reply on the phone.'**
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
  /// **'Notification access is off, so nothing is mirrored.'**
  String get phoneHomePaused;

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
  /// **'Notification access is off on {device}. Open Ferret on {device} to fix it.'**
  String homeAccessOff(String device);

  /// No description provided for @homeUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach notifications on {device}.'**
  String homeUnreachable(String device);

  /// No description provided for @howTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on Notifications on {device}'**
  String howTitle(String device);

  /// No description provided for @howBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}, open Ferret, tap Turn on more, then Notifications. Ferret asks for notification access and lets you pick the apps.'**
  String howBody(String device);

  /// No description provided for @how.
  ///
  /// In en, this message translates to:
  /// **'How?'**
  String get how;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_NotificationsLocalizationsDelegate old) => false;
}

NotificationsLocalizations lookupNotificationsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return NotificationsLocalizationsEn();
  }

  throw FlutterError(
    'NotificationsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
