import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'calls_localizations_en.dart';
import 'calls_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CallsLocalizations
/// returned by `CallsLocalizations.of(context)`.
///
/// Applications need to include `CallsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/calls_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CallsLocalizations.localizationsDelegates,
///   supportedLocales: CallsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the CallsLocalizations.supportedLocales
/// property.
abstract class CallsLocalizations {
  CallsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CallsLocalizations of(BuildContext context) {
    return Localizations.of<CallsLocalizations>(context, CallsLocalizations)!;
  }

  static const LocalizationsDelegate<CallsLocalizations> delegate =
      _CallsLocalizationsDelegate();

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
  /// **'Calls'**
  String get title;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @unknownCaller.
  ///
  /// In en, this message translates to:
  /// **'Unknown caller'**
  String get unknownCaller;

  /// No description provided for @incomingOn.
  ///
  /// In en, this message translates to:
  /// **'Incoming call on {device}'**
  String incomingOn(String device);

  /// An outgoing call being dialled by that phone
  ///
  /// In en, this message translates to:
  /// **'Calling from {device}'**
  String callingOn(String device);

  /// No description provided for @onCallOn.
  ///
  /// In en, this message translates to:
  /// **'On a call on {device}'**
  String onCallOn(String device);

  /// No description provided for @onHoldOn.
  ///
  /// In en, this message translates to:
  /// **'On hold on {device}'**
  String onHoldOn(String device);

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @hangUp.
  ///
  /// In en, this message translates to:
  /// **'Hang up'**
  String get hangUp;

  /// Activity row while a phone rings, such as: Alex is calling Pixel 9
  ///
  /// In en, this message translates to:
  /// **'{caller} is calling {device}'**
  String activityRinging(String caller, String device);

  /// No description provided for @activityOnCall.
  ///
  /// In en, this message translates to:
  /// **'On a call with {caller}'**
  String activityOnCall(String caller);

  /// No description provided for @activityDialing.
  ///
  /// In en, this message translates to:
  /// **'Calling {caller}'**
  String activityDialing(String caller);

  /// No description provided for @activityOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold with {caller}'**
  String activityOnHold(String caller);

  /// Mutes the ringing phone without declining the call
  ///
  /// In en, this message translates to:
  /// **'Silence'**
  String get silence;

  /// No description provided for @silenced.
  ///
  /// In en, this message translates to:
  /// **'Ringer silenced'**
  String get silenced;

  /// No description provided for @audioStays.
  ///
  /// In en, this message translates to:
  /// **'Audio stays on {device} for now. Talk on {device} or its headset.'**
  String audioStays(String device);

  /// No description provided for @outcomeNoCall.
  ///
  /// In en, this message translates to:
  /// **'That call is already over.'**
  String get outcomeNoCall;

  /// No description provided for @outcomeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Calls are off on {device}. On {device}: Ferret → Do more → Calls.'**
  String outcomeDisabled(String device);

  /// No description provided for @outcomePermission.
  ///
  /// In en, this message translates to:
  /// **'{device} hasn\'t allowed this yet. On {device}: Ferret → Settings → To your computer, then allow it under Calls.'**
  String outcomePermission(String device);

  /// No description provided for @outcomeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device}\'s Android version can\'t do this.'**
  String outcomeUnsupported(String device);

  /// No description provided for @outcomeInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a phone number.'**
  String get outcomeInvalidNumber;

  /// No description provided for @outcomeFailed.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t do that. Try it on {device}.'**
  String outcomeFailed(String device);

  /// No description provided for @outcomeUnreachable.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer. Check that it\'s connected.'**
  String outcomeUnreachable(String device);

  /// No description provided for @noticeIncomingBody.
  ///
  /// In en, this message translates to:
  /// **'Incoming call · {device}'**
  String noticeIncomingBody(String device);

  /// No description provided for @noticeMissedTitle.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get noticeMissedTitle;

  /// No description provided for @noticeMissedBody.
  ///
  /// In en, this message translates to:
  /// **'{caller} · {device}'**
  String noticeMissedBody(String caller, String device);

  /// No description provided for @callAction.
  ///
  /// In en, this message translates to:
  /// **'Call…'**
  String get callAction;

  /// No description provided for @dialerTitle.
  ///
  /// In en, this message translates to:
  /// **'Call from {device}'**
  String dialerTitle(String device);

  /// No description provided for @numberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get numberLabel;

  /// No description provided for @numberHint.
  ///
  /// In en, this message translates to:
  /// **'+1 555 0100'**
  String get numberHint;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @callStarted.
  ///
  /// In en, this message translates to:
  /// **'{device} is calling. Audio stays on {device} for now.'**
  String callStarted(String device);

  /// Heading above the number field and Call button on a phone's Calls page
  ///
  /// In en, this message translates to:
  /// **'New call'**
  String get dialSection;

  /// No description provided for @recentCalls.
  ///
  /// In en, this message translates to:
  /// **'Recent calls'**
  String get recentCalls;

  /// No description provided for @recentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent calls.'**
  String get recentEmpty;

  /// No description provided for @recentLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading recent calls…'**
  String get recentLoading;

  /// No description provided for @logUnreachable.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer. Check that it\'s connected.'**
  String logUnreachable(String device);

  /// No description provided for @logPermission.
  ///
  /// In en, this message translates to:
  /// **'{device} doesn\'t let Ferret read its recent calls. On {device}: Ferret → Settings → To your computer, then allow Call logs under Calls.'**
  String logPermission(String device);

  /// No description provided for @logDisabled.
  ///
  /// In en, this message translates to:
  /// **'Calls are off on {device}. On {device}: Ferret → Do more → Calls.'**
  String logDisabled(String device);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Call log: type of the call
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get typeIncoming;

  /// Call log: type of the call
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get typeOutgoing;

  /// Call log: type of the call
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get typeMissed;

  /// No description provided for @typeRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get typeRejected;

  /// No description provided for @privateNumber.
  ///
  /// In en, this message translates to:
  /// **'Private number'**
  String get privateNumber;

  /// No description provided for @explainer.
  ///
  /// In en, this message translates to:
  /// **'See who\'s calling and answer from your computer.'**
  String get explainer;

  /// No description provided for @explainerDetail.
  ///
  /// In en, this message translates to:
  /// **'Android will ask for Phone, Call logs and Contacts. Calls only go to your own paired devices. Audio stays on this phone for now.'**
  String get explainerDetail;

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
  /// **'Calls are on, but Ferret can\'t see this phone\'s calls yet.'**
  String get phoneHomePaused;

  /// No description provided for @permissionOff.
  ///
  /// In en, this message translates to:
  /// **'Ferret can\'t see calls yet'**
  String get permissionOff;

  /// No description provided for @permissionStillOff.
  ///
  /// In en, this message translates to:
  /// **'Still off. Android won\'t ask again, so allow it in the app\'s settings.'**
  String get permissionStillOff;

  /// No description provided for @permissionHowTo.
  ///
  /// In en, this message translates to:
  /// **'Allow Phone so Ferret can tell your computer when a call comes in.'**
  String get permissionHowTo;

  /// No description provided for @permissionHowToSettings.
  ///
  /// In en, this message translates to:
  /// **'In the app\'s settings, open Permissions, then Phone, then Allow. Do the same for Call logs and Contacts.'**
  String get permissionHowToSettings;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get allow;

  /// No description provided for @allowRest.
  ///
  /// In en, this message translates to:
  /// **'Allow the rest'**
  String get allowRest;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openSettings;

  /// No description provided for @openSettingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Settings. Open Android Settings, then Apps, then Ferret, then Permissions.'**
  String get openSettingsFailed;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Your computers see this phone\'s calls'**
  String get ready;

  /// No description provided for @capNumbers.
  ///
  /// In en, this message translates to:
  /// **'Who is calling, and recent calls'**
  String get capNumbers;

  /// No description provided for @capContacts.
  ///
  /// In en, this message translates to:
  /// **'Names and photos'**
  String get capContacts;

  /// No description provided for @capAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer, decline and hang up'**
  String get capAnswer;

  /// No description provided for @capDial.
  ///
  /// In en, this message translates to:
  /// **'Start calls from your computer'**
  String get capDial;

  /// No description provided for @audioOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Call audio stays on this phone for now.'**
  String get audioOnPhone;

  /// No description provided for @showIncoming.
  ///
  /// In en, this message translates to:
  /// **'Show incoming calls'**
  String get showIncoming;

  /// No description provided for @showIncomingDetail.
  ///
  /// In en, this message translates to:
  /// **'A notification with Answer and Decline when your phone rings.'**
  String get showIncomingDetail;

  /// No description provided for @settingsAudio.
  ///
  /// In en, this message translates to:
  /// **'Call audio stays on the phone for now. Ferret answers the call; you talk on the phone or its headset.'**
  String get settingsAudio;

  /// No description provided for @healthNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer'**
  String healthNoAnswer(String device);

  /// No description provided for @healthOff.
  ///
  /// In en, this message translates to:
  /// **'Off on {device}'**
  String healthOff(String device);

  /// No description provided for @healthNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'Android turned off Ferret\'s access'**
  String get healthNeedsPermission;

  /// No description provided for @healthLimited.
  ///
  /// In en, this message translates to:
  /// **'Shows calls. Answer on {device}'**
  String healthLimited(String device);

  /// No description provided for @healthOk.
  ///
  /// In en, this message translates to:
  /// **'Answer and decline'**
  String get healthOk;

  /// No description provided for @healthChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get healthChecking;

  /// No description provided for @healthOffHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}: Ferret → Do more → Calls.'**
  String healthOffHelp(String device);

  /// No description provided for @healthNeedsPermissionHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret and tap Fix.'**
  String healthNeedsPermissionHelp(String device);

  /// No description provided for @healthLocalOffHelp.
  ///
  /// In en, this message translates to:
  /// **'On this phone: Settings → To your computer → Calls.'**
  String get healthLocalOffHelp;

  /// No description provided for @healthLocalPushFailedHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret. The next call shows there.'**
  String healthLocalPushFailedHelp(String device);

  /// Settings row value on the phone: Calls are on but Android hides them from Ferret.
  ///
  /// In en, this message translates to:
  /// **'Needs access'**
  String get settingsNeedsAccess;

  /// Settings row value on a computer.
  ///
  /// In en, this message translates to:
  /// **'Needs access on {device}'**
  String settingsNeedsAccessOn(String device);

  /// No description provided for @healthLocalOff.
  ///
  /// In en, this message translates to:
  /// **'Off on this phone'**
  String get healthLocalOff;

  /// No description provided for @healthLocalNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'Android turned off Ferret\'s access'**
  String get healthLocalNeedsPermission;

  /// No description provided for @healthLocalPushFailed.
  ///
  /// In en, this message translates to:
  /// **'The last call didn\'t reach {device}'**
  String healthLocalPushFailed(String device);

  /// No description provided for @healthLocalOk.
  ///
  /// In en, this message translates to:
  /// **'{device} sees this phone\'s calls'**
  String healthLocalOk(String device);
}

class _CallsLocalizationsDelegate
    extends LocalizationsDelegate<CallsLocalizations> {
  const _CallsLocalizationsDelegate();

  @override
  Future<CallsLocalizations> load(Locale locale) {
    return SynchronousFuture<CallsLocalizations>(
      lookupCallsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_CallsLocalizationsDelegate old) => false;
}

CallsLocalizations lookupCallsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return CallsLocalizationsEn();
    case 'vi':
      return CallsLocalizationsVi();
  }

  throw FlutterError(
    'CallsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
