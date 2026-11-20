import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'actions_localizations_en.dart';
import 'actions_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ActionsLocalizations
/// returned by `ActionsLocalizations.of(context)`.
///
/// Applications need to include `ActionsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/actions_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ActionsLocalizations.localizationsDelegates,
///   supportedLocales: ActionsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ActionsLocalizations.supportedLocales
/// property.
abstract class ActionsLocalizations {
  ActionsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ActionsLocalizations of(BuildContext context) {
    return Localizations.of<ActionsLocalizations>(
      context,
      ActionsLocalizations,
    )!;
  }

  static const LocalizationsDelegate<ActionsLocalizations> delegate =
      _ActionsLocalizationsDelegate();

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
  /// **'Computer actions'**
  String get title;

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

  /// No description provided for @allowOnce.
  ///
  /// In en, this message translates to:
  /// **'Allow once'**
  String get allowOnce;

  /// No description provided for @allowAlways.
  ///
  /// In en, this message translates to:
  /// **'Always allow'**
  String get allowAlways;

  /// No description provided for @dontAllow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t allow'**
  String get dontAllow;

  /// No description provided for @actionSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get actionSleep;

  /// No description provided for @actionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get actionRestart;

  /// No description provided for @actionShutDown.
  ///
  /// In en, this message translates to:
  /// **'Shut down'**
  String get actionShutDown;

  /// No description provided for @actionMute.
  ///
  /// In en, this message translates to:
  /// **'Mute or unmute'**
  String get actionMute;

  /// No description provided for @actionVolumeUp.
  ///
  /// In en, this message translates to:
  /// **'Volume up'**
  String get actionVolumeUp;

  /// No description provided for @actionVolumeDown.
  ///
  /// In en, this message translates to:
  /// **'Volume down'**
  String get actionVolumeDown;

  /// No description provided for @actionVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get actionVolume;

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Let {device} put {computer, select, mac{this Mac} windows{this PC} other{this computer}} to sleep?'**
  String consentSleep(String device, String computer);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Let {device} restart {computer, select, mac{this Mac} windows{this PC} other{this computer}}?'**
  String consentRestart(String device, String computer);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Let {device} shut down {computer, select, mac{this Mac} windows{this PC} other{this computer}}?'**
  String consentShutDown(String device, String computer);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Let {device} change the volume of {computer, select, mac{this Mac} windows{this PC} other{this computer}}?'**
  String consentSound(String device, String computer);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Let {device} run “{name}” on {computer, select, mac{this Mac} windows{this PC} other{this computer}}?'**
  String consentCustom(String device, String name, String computer);

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'Always allow, and {device} does this without asking next time. You can take that back on its page.'**
  String consentBody(String device);

  /// No description provided for @consentCountsDown.
  ///
  /// In en, this message translates to:
  /// **'You get 10 seconds to cancel before it happens.'**
  String get consentCountsDown;

  /// No description provided for @consentCommandLabel.
  ///
  /// In en, this message translates to:
  /// **'It runs exactly this:'**
  String get consentCommandLabel;

  /// No description provided for @consentCommandNotice.
  ///
  /// In en, this message translates to:
  /// **'Runs: {command}'**
  String consentCommandNotice(String command);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Restarting {computer, select, mac{this Mac} windows{this PC} other{this computer}} in {seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String countdownRestart(String computer, int seconds);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Shutting down {computer, select, mac{this Mac} windows{this PC} other{this computer}} in {seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String countdownShutDown(String computer, int seconds);

  /// No description provided for @countdownBody.
  ///
  /// In en, this message translates to:
  /// **'{device} asked for it. Save your work, or cancel.'**
  String countdownBody(String device);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'{device} is restarting {computer, select, mac{this Mac} windows{this PC} other{this computer}}'**
  String countdownNoticeRestart(String device, String computer);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'{device} is shutting down {computer, select, mac{this Mac} windows{this PC} other{this computer}}'**
  String countdownNoticeShutDown(String device, String computer);

  /// No description provided for @countdownNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'It happens in 10 seconds. Cancel to stop it.'**
  String get countdownNoticeBody;

  /// No description provided for @recordTitle.
  ///
  /// In en, this message translates to:
  /// **'{action}, asked by {device}'**
  String recordTitle(String action, String device);

  /// No description provided for @recordDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get recordDone;

  /// No description provided for @recordDenied.
  ///
  /// In en, this message translates to:
  /// **'You said no.'**
  String get recordDenied;

  /// No description provided for @recordNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Nobody answered here.'**
  String get recordNotAnswered;

  /// No description provided for @recordCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled here.'**
  String get recordCancelled;

  /// No description provided for @recordFailed.
  ///
  /// In en, this message translates to:
  /// **'It didn\'t work.'**
  String get recordFailed;

  /// No description provided for @recordExitCode.
  ///
  /// In en, this message translates to:
  /// **'Ended with code {code}.'**
  String recordExitCode(int code);

  /// No description provided for @recordTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Stopped: it ran longer than {seconds} seconds.'**
  String recordTimedOut(int seconds);

  /// No description provided for @recordNotStarted.
  ///
  /// In en, this message translates to:
  /// **'It couldn\'t start. Check the command in Settings.'**
  String get recordNotStarted;

  /// Title over a computer's Sleep, Restart, Shut down and Volume on its page.
  ///
  /// In en, this message translates to:
  /// **'Power and sound'**
  String get groupTitle;

  /// No description provided for @groupHint.
  ///
  /// In en, this message translates to:
  /// **'The first time, {device} asks on its own screen.'**
  String groupHint(String device);

  /// No description provided for @groupYourActions.
  ///
  /// In en, this message translates to:
  /// **'Your actions'**
  String get groupYourActions;

  /// No description provided for @restartEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Restart…'**
  String get restartEllipsis;

  /// No description provided for @shutDownEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Shut down…'**
  String get shutDownEllipsis;

  /// No description provided for @confirmRestartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart {device}?'**
  String confirmRestartTitle(String device);

  /// No description provided for @confirmRestartBody.
  ///
  /// In en, this message translates to:
  /// **'It counts down 10 seconds first, and anyone at {device} can cancel. Ferret reconnects once it\'s back.'**
  String confirmRestartBody(String device);

  /// No description provided for @confirmShutDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Shut down {device}?'**
  String confirmShutDownTitle(String device);

  /// No description provided for @confirmShutDownBody.
  ///
  /// In en, this message translates to:
  /// **'It counts down 10 seconds first, and anyone at {device} can cancel. After it\'s off, Ferret can\'t reach it until someone turns it on.'**
  String confirmShutDownBody(String device);

  /// No description provided for @outAsking.
  ///
  /// In en, this message translates to:
  /// **'Asking {device}: {action}…'**
  String outAsking(String device, String action);

  /// No description provided for @outAskingDetail.
  ///
  /// In en, this message translates to:
  /// **'If it asks, answer on {device}.'**
  String outAskingDetail(String device);

  /// No description provided for @outCountingDown.
  ///
  /// In en, this message translates to:
  /// **'{device} counts down 10 seconds first.'**
  String outCountingDown(String device);

  /// No description provided for @outSleep.
  ///
  /// In en, this message translates to:
  /// **'{device} is going to sleep'**
  String outSleep(String device);

  /// No description provided for @outRestart.
  ///
  /// In en, this message translates to:
  /// **'{device} is restarting'**
  String outRestart(String device);

  /// No description provided for @outShutDown.
  ///
  /// In en, this message translates to:
  /// **'{device} is shutting down'**
  String outShutDown(String device);

  /// No description provided for @outCustom.
  ///
  /// In en, this message translates to:
  /// **'{device} ran “{name}”'**
  String outCustom(String device, String name);

  /// No description provided for @outDenied.
  ///
  /// In en, this message translates to:
  /// **'{device} said no'**
  String outDenied(String device);

  /// No description provided for @outNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Nobody answered on {device}'**
  String outNotAnswered(String device);

  /// No description provided for @outNotAnsweredDetail.
  ///
  /// In en, this message translates to:
  /// **'The question stays on its screen for a minute. Try again when someone is there.'**
  String get outNotAnsweredDetail;

  /// No description provided for @outBusy.
  ///
  /// In en, this message translates to:
  /// **'{device} is busy with another request'**
  String outBusy(String device);

  /// No description provided for @outTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Actions are off on {device}'**
  String outTurnedOff(String device);

  /// No description provided for @outTurnedOffDetail.
  ///
  /// In en, this message translates to:
  /// **'Turn them on there: Settings → Control.'**
  String get outTurnedOffDetail;

  /// No description provided for @outUnknown.
  ///
  /// In en, this message translates to:
  /// **'{device} no longer has that action'**
  String outUnknown(String device);

  /// No description provided for @outFailed.
  ///
  /// In en, this message translates to:
  /// **'It didn\'t work on {device}'**
  String outFailed(String device);

  /// No description provided for @outFailedCode.
  ///
  /// In en, this message translates to:
  /// **'“{name}” ended with code {code} there.'**
  String outFailedCode(String name, int code);

  /// No description provided for @outCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled on {device}'**
  String outCancelled(String device);

  /// No description provided for @outTimedOut.
  ///
  /// In en, this message translates to:
  /// **'“{name}” ran too long on {device}'**
  String outTimedOut(String name, String device);

  /// No description provided for @outTimedOutDetail.
  ///
  /// In en, this message translates to:
  /// **'It was stopped there.'**
  String get outTimedOutDetail;

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Let your devices run actions on {computer, select, mac{this Mac} windows{this PC} other{this computer}}'**
  String settingsEnabled(String computer);

  /// No description provided for @settingsEnabledBody.
  ///
  /// In en, this message translates to:
  /// **'Sleep, restart, shut down, volume, and your own actions. Each device asks here the first time.'**
  String get settingsEnabledBody;

  /// No description provided for @settingsPerDevice.
  ///
  /// In en, this message translates to:
  /// **'What a device may do without asking is on its page.'**
  String get settingsPerDevice;

  /// No description provided for @yourActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your actions'**
  String get yourActionsTitle;

  /// No description provided for @yourActionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'A command, a script or a shortcut of yours, under a name. Your devices only ever see the name.'**
  String get yourActionsEmpty;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add action'**
  String get addAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @editNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New action'**
  String get editNewTitle;

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit action'**
  String get editTitle;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editName;

  /// No description provided for @editNameHint.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get editNameHint;

  /// No description provided for @editCommand.
  ///
  /// In en, this message translates to:
  /// **'Command, script or shortcut'**
  String get editCommand;

  /// No description provided for @editCommandHelp.
  ///
  /// In en, this message translates to:
  /// **'It runs as you, without a shell: no pipes, no &&. Put those in a script and give its path. It\'s stopped after {seconds} seconds.'**
  String editCommandHelp(int seconds);

  /// No description provided for @editCommandChanged.
  ///
  /// In en, this message translates to:
  /// **'A new command asks every device again.'**
  String get editCommandChanged;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions run here'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing ran yet.'**
  String get historyEmpty;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @summaryOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get summaryOff;

  /// No description provided for @summaryOn.
  ///
  /// In en, this message translates to:
  /// **'Asks first'**
  String get summaryOn;

  /// No description provided for @summaryOwn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 of your own} other{{count} of your own}}'**
  String summaryOwn(int count);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Put {computer, select, mac{this Mac} windows{this PC} other{this computer}} to sleep without asking'**
  String permissionSleep(String computer);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Restart {computer, select, mac{this Mac} windows{this PC} other{this computer}} without asking'**
  String permissionRestart(String computer);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Shut down {computer, select, mac{this Mac} windows{this PC} other{this computer}} without asking'**
  String permissionShutDown(String computer);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Change the volume of {computer, select, mac{this Mac} windows{this PC} other{this computer}} without asking'**
  String permissionSound(String computer);

  /// No description provided for @permissionCustom.
  ///
  /// In en, this message translates to:
  /// **'Run “{name}” without asking'**
  String permissionCustom(String name);

  /// No description provided for @healthOffers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 action} other{{count} actions}}. {device} asks the first time.'**
  String healthOffers(int count, String device);

  /// No description provided for @healthRemoteOff.
  ///
  /// In en, this message translates to:
  /// **'Actions are off on {device}'**
  String healthRemoteOff(String device);

  /// No description provided for @healthRemoteOffHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}, open Settings → Control and turn on Computer actions.'**
  String healthRemoteOffHelp(String device);

  /// No description provided for @healthHostAsks.
  ///
  /// In en, this message translates to:
  /// **'Asks you here the first time'**
  String get healthHostAsks;

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Actions are off on {computer, select, mac{this Mac} windows{this PC} other{this computer}}'**
  String healthHostOff(String computer);

  /// No description provided for @healthHostOffHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn on Computer actions in Settings → Control.'**
  String get healthHostOffHelp;

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock when your phone leaves'**
  String get leaveTitle;

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Lock {computer, select, mac{this Mac} windows{this PC} other{this computer}} when {device} leaves'**
  String leaveSwitch(String device, String computer);

  /// No description provided for @leaveSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'When {device} drops off the Wi-Fi and stays gone for {minutes, plural, =1{1 minute} other{{minutes} minutes}}.'**
  String leaveSwitchBody(String device, int minutes);

  /// No description provided for @leaveAfter.
  ///
  /// In en, this message translates to:
  /// **'Lock after'**
  String get leaveAfter;

  /// No description provided for @leaveMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String leaveMinutes(int minutes);

  /// No description provided for @leaveNote.
  ///
  /// In en, this message translates to:
  /// **'It waits until nobody has touched the keyboard or mouse for a minute, then gives you 10 seconds to cancel. It never unlocks. Pausing Ferret on the phone isn\'t leaving.'**
  String get leaveNote;

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Pair an Android phone to lock {computer, select, mac{this Mac} windows{this PC} other{this computer}} when it leaves. iPhone can\'t: iOS stops Ferret in the background, so it would look gone all the time.'**
  String leaveNoPhones(String computer);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Locking {computer, select, mac{this Mac} windows{this PC} other{this computer}} in {seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String leaveCountdownTitle(String computer, int seconds);

  /// No description provided for @leaveCountdownBody.
  ///
  /// In en, this message translates to:
  /// **'{device} left. Cancel if you\'re still here.'**
  String leaveCountdownBody(String device);

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Locking {computer, select, mac{this Mac} windows{this PC} other{this computer}}: {device} left'**
  String leaveNoticeTitle(String computer, String device);

  /// No description provided for @leaveNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Cancel to keep it unlocked.'**
  String get leaveNoticeBody;

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Locked {computer, select, mac{this Mac} windows{this PC} other{this computer}}: {device} left'**
  String leaveLocked(String computer, String device);

  /// No description provided for @leaveLockedDetail.
  ///
  /// In en, this message translates to:
  /// **'Gone for {minutes, plural, =1{1 minute} other{{minutes} minutes}}, with nobody at the keyboard'**
  String leaveLockedDetail(int minutes);

  /// No description provided for @leaveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Stayed unlocked after {device} left'**
  String leaveCancelled(String device);

  /// No description provided for @leaveCancelledDetail.
  ///
  /// In en, this message translates to:
  /// **'You cancelled the lock'**
  String get leaveCancelledDetail;

  /// computer is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t lock {computer, select, mac{this Mac} windows{this PC} other{this computer}} after {device} left'**
  String leaveFailed(String computer, String device);

  /// No description provided for @leaveFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'The system said no. Lock it by hand.'**
  String get leaveFailedDetail;

  /// No description provided for @leavePermissionDetail.
  ///
  /// In en, this message translates to:
  /// **'After {minutes, plural, =1{1 minute} other{{minutes} minutes}} away, when nobody is at the keyboard'**
  String leavePermissionDetail(int minutes);
}

class _ActionsLocalizationsDelegate
    extends LocalizationsDelegate<ActionsLocalizations> {
  const _ActionsLocalizationsDelegate();

  @override
  Future<ActionsLocalizations> load(Locale locale) {
    return SynchronousFuture<ActionsLocalizations>(
      lookupActionsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_ActionsLocalizationsDelegate old) => false;
}

ActionsLocalizations lookupActionsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ActionsLocalizationsEn();
    case 'vi':
      return ActionsLocalizationsVi();
  }

  throw FlutterError(
    'ActionsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
