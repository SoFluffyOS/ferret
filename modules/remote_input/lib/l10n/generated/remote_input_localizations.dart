import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'remote_input_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of RemoteInputLocalizations
/// returned by `RemoteInputLocalizations.of(context)`.
///
/// Applications need to include `RemoteInputLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/remote_input_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: RemoteInputLocalizations.localizationsDelegates,
///   supportedLocales: RemoteInputLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the RemoteInputLocalizations.supportedLocales
/// property.
abstract class RemoteInputLocalizations {
  RemoteInputLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static RemoteInputLocalizations of(BuildContext context) {
    return Localizations.of<RemoteInputLocalizations>(
      context,
      RemoteInputLocalizations,
    )!;
  }

  static const LocalizationsDelegate<RemoteInputLocalizations> delegate =
      _RemoteInputLocalizationsDelegate();

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
  /// **'Control'**
  String get title;

  /// No description provided for @useAsTouchpad.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get useAsTouchpad;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Let {device} control this computer?'**
  String consentTitle(String device);

  /// No description provided for @consentBody.
  ///
  /// In en, this message translates to:
  /// **'{device} can move the pointer, click and type here until you stop it. You\'ll see it the whole time.'**
  String consentBody(String device);

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

  /// No description provided for @controlledBy.
  ///
  /// In en, this message translates to:
  /// **'{device} is controlling this computer'**
  String controlledBy(String device);

  /// No description provided for @controlledSince.
  ///
  /// In en, this message translates to:
  /// **'Since {time}. It can move the pointer and type.'**
  String controlledSince(String time);

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop control'**
  String get stop;

  /// Activity row while a device controls this computer. host is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'{device} is controlling {host, select, mac{this Mac} windows{this PC} other{this computer}}'**
  String activityControlling(String device, String host);

  /// Button on the Activity row while a device controls this computer; the row already says what is controlled.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get activityStop;

  /// Activity row once a device stopped controlling this computer. host is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'{device} controlled {host, select, mac{this Mac} windows{this PC} other{this computer}}'**
  String activityControlled(String device, String host);

  /// No description provided for @activityControlledFor.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{For less than a minute} =1{For 1 min} other{For {minutes} min}}'**
  String activityControlledFor(int minutes);

  /// No description provided for @activeNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Stop control to take this computer back.'**
  String get activeNoticeBody;

  /// No description provided for @permissionTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t control this computer yet'**
  String permissionTitle(String device);

  /// No description provided for @permissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Ferret in Accessibility settings, then try again on {device}.'**
  String permissionBody(String device);

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @auditLine.
  ///
  /// In en, this message translates to:
  /// **'{device} controlled this computer for {minutes, plural, =0{less than a minute} =1{1 min} other{{minutes} min}} at {time}'**
  String auditLine(String device, int minutes, String time);

  /// No description provided for @settingsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Let my phones control this computer'**
  String get settingsEnabled;

  /// No description provided for @settingsEnabledBody.
  ///
  /// In en, this message translates to:
  /// **'A phone becomes its touchpad and keyboard. Each phone asks you first.'**
  String get settingsEnabledBody;

  /// No description provided for @statusReadyQuartz.
  ///
  /// In en, this message translates to:
  /// **'On. Uses Accessibility access.'**
  String get statusReadyQuartz;

  /// No description provided for @statusReadySendInput.
  ///
  /// In en, this message translates to:
  /// **'On. Apps running as administrator can\'t be controlled.'**
  String get statusReadySendInput;

  /// No description provided for @statusReadyUinput.
  ///
  /// In en, this message translates to:
  /// **'On. Uses a virtual input device.'**
  String get statusReadyUinput;

  /// No description provided for @statusReadyXdotool.
  ///
  /// In en, this message translates to:
  /// **'On. Uses xdotool, which works on X11 only.'**
  String get statusReadyXdotool;

  /// No description provided for @statusReadyYdotool.
  ///
  /// In en, this message translates to:
  /// **'On. Uses ydotool.'**
  String get statusReadyYdotool;

  /// No description provided for @statusNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'Accessibility access is off'**
  String get statusNeedsPermission;

  /// No description provided for @statusNeedsPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'macOS asks before any app may move the pointer or type. Turn on Ferret in the list, then come back.'**
  String get statusNeedsPermissionBody;

  /// No description provided for @allowAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get allowAccess;

  /// No description provided for @statusNoLinuxBackend.
  ///
  /// In en, this message translates to:
  /// **'This computer can\'t be controlled yet'**
  String get statusNoLinuxBackend;

  /// No description provided for @statusNoLinuxBackendBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret needs write access to /dev/uinput, or xdotool (X11) or ydotool (Wayland). Install one with your package manager, then check again.'**
  String get statusNoLinuxBackendBody;

  /// No description provided for @statusYdotoolNotRunning.
  ///
  /// In en, this message translates to:
  /// **'ydotool is installed, but its service isn\'t running'**
  String get statusYdotoolNotRunning;

  /// No description provided for @statusYdotoolNotRunningBody.
  ///
  /// In en, this message translates to:
  /// **'Start the ydotoold service, then check again.'**
  String get statusYdotoolNotRunningBody;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get statusFailed;

  /// No description provided for @statusFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret doesn\'t know yet whether it may control this computer. Check again.'**
  String get statusFailedBody;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @settingsPerDevice.
  ///
  /// In en, this message translates to:
  /// **'To let one phone control this computer without asking, open the phone from Home.'**
  String get settingsPerDevice;

  /// No description provided for @settingsHostTitle.
  ///
  /// In en, this message translates to:
  /// **'Pointer and keyboard'**
  String get settingsHostTitle;

  /// No description provided for @settingsTouchpadTitle.
  ///
  /// In en, this message translates to:
  /// **'Touchpad'**
  String get settingsTouchpadTitle;

  /// No description provided for @summaryOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get summaryOn;

  /// No description provided for @summaryOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get summaryOff;

  /// No description provided for @summaryNeedsAccess.
  ///
  /// In en, this message translates to:
  /// **'Needs access'**
  String get summaryNeedsAccess;

  /// No description provided for @summaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get summaryUnavailable;

  /// host is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Control {host, select, mac{this Mac} windows{this PC} other{this computer}} without asking'**
  String permissionAlways(String host);

  /// No description provided for @permissionAlwaysDetail.
  ///
  /// In en, this message translates to:
  /// **'You still see it the whole time, with Stop control.'**
  String get permissionAlwaysDetail;

  /// No description provided for @permissionAlwaysOff.
  ///
  /// In en, this message translates to:
  /// **'Control is off. Turn it on in Settings → Control.'**
  String get permissionAlwaysOff;

  /// No description provided for @settingsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get settingsHistoryTitle;

  /// No description provided for @settingsHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No device controlled this computer yet.'**
  String get settingsHistoryEmpty;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @settingsSpeed.
  ///
  /// In en, this message translates to:
  /// **'Touchpad speed'**
  String get settingsSpeed;

  /// No description provided for @settingsSpeedBody.
  ///
  /// In en, this message translates to:
  /// **'How far the pointer moves for the same finger move.'**
  String get settingsSpeedBody;

  /// No description provided for @settingsNaturalScroll.
  ///
  /// In en, this message translates to:
  /// **'Natural scrolling'**
  String get settingsNaturalScroll;

  /// No description provided for @settingsNaturalScrollBody.
  ///
  /// In en, this message translates to:
  /// **'Move two fingers up to scroll down, like on your phone\'s screen.'**
  String get settingsNaturalScrollBody;

  /// No description provided for @requesting.
  ///
  /// In en, this message translates to:
  /// **'Asking {device}…'**
  String requesting(String device);

  /// No description provided for @waitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {device}'**
  String waitingTitle(String device);

  /// No description provided for @waitingBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: click Allow once. Pick Always allow and it won\'t ask again.'**
  String waitingBody(String device);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @touchpadHint.
  ///
  /// In en, this message translates to:
  /// **'One finger moves. Tap to click, hold to right-click. Two fingers scroll. Tap, then slide to drag.'**
  String get touchpadHint;

  /// No description provided for @leftButton.
  ///
  /// In en, this message translates to:
  /// **'Left click'**
  String get leftButton;

  /// No description provided for @rightButton.
  ///
  /// In en, this message translates to:
  /// **'Right click'**
  String get rightButton;

  /// No description provided for @keyboardHint.
  ///
  /// In en, this message translates to:
  /// **'Type here'**
  String get keyboardHint;

  /// No description provided for @showKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get showKeyboard;

  /// No description provided for @hideKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Hide keyboard'**
  String get hideKeyboard;

  /// No description provided for @keyEscape.
  ///
  /// In en, this message translates to:
  /// **'Esc'**
  String get keyEscape;

  /// No description provided for @keyTab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get keyTab;

  /// No description provided for @keyEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get keyEnter;

  /// No description provided for @keyBackspace.
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get keyBackspace;

  /// No description provided for @keyLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get keyLeft;

  /// No description provided for @keyRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get keyRight;

  /// No description provided for @keyUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get keyUp;

  /// No description provided for @keyDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get keyDown;

  /// No description provided for @mediaPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get mediaPrevious;

  /// No description provided for @mediaPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play or pause'**
  String get mediaPlayPause;

  /// No description provided for @mediaNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get mediaNext;

  /// No description provided for @volumeDown.
  ///
  /// In en, this message translates to:
  /// **'Volume down'**
  String get volumeDown;

  /// No description provided for @volumeMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get volumeMute;

  /// No description provided for @volumeUp.
  ///
  /// In en, this message translates to:
  /// **'Volume up'**
  String get volumeUp;

  /// No description provided for @modShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get modShift;

  /// No description provided for @modControl.
  ///
  /// In en, this message translates to:
  /// **'Ctrl'**
  String get modControl;

  /// No description provided for @modAlt.
  ///
  /// In en, this message translates to:
  /// **'Alt'**
  String get modAlt;

  /// No description provided for @modAltMac.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get modAltMac;

  /// No description provided for @modMeta.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get modMeta;

  /// No description provided for @modMetaMac.
  ///
  /// In en, this message translates to:
  /// **'Cmd'**
  String get modMetaMac;

  /// No description provided for @modMetaLinux.
  ///
  /// In en, this message translates to:
  /// **'Super'**
  String get modMetaLinux;

  /// No description provided for @deniedDenied.
  ///
  /// In en, this message translates to:
  /// **'{device} said no.'**
  String deniedDenied(String device);

  /// No description provided for @deniedTimeout.
  ///
  /// In en, this message translates to:
  /// **'Nobody answered on {device}.'**
  String deniedTimeout(String device);

  /// No description provided for @deniedBusy.
  ///
  /// In en, this message translates to:
  /// **'Another device controls {device} right now.'**
  String deniedBusy(String device);

  /// No description provided for @deniedNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'{device} needs Accessibility access first. On {device}: open Ferret and allow it.'**
  String deniedNeedsPermission(String device);

  /// No description provided for @deniedUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t be controlled yet. On {device}: open Ferret → Settings → Control to see why.'**
  String deniedUnsupported(String device);

  /// No description provided for @deniedTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Control is off on {device}. On {device}: open Ferret → Settings → Control and turn it on.'**
  String deniedTurnedOff(String device);

  /// No description provided for @deniedVersion.
  ///
  /// In en, this message translates to:
  /// **'{device} runs an older Ferret. Update Ferret on {device}, then try again.'**
  String deniedVersion(String device);

  /// No description provided for @stoppedOnHost.
  ///
  /// In en, this message translates to:
  /// **'Someone stopped it on {device}.'**
  String stoppedOnHost(String device);

  /// No description provided for @stoppedIdle.
  ///
  /// In en, this message translates to:
  /// **'Stopped after a long time without input.'**
  String get stoppedIdle;

  /// No description provided for @stoppedRevoked.
  ///
  /// In en, this message translates to:
  /// **'{device} no longer lets this phone control it.'**
  String stoppedRevoked(String device);

  /// No description provided for @stoppedFailed.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t move the pointer or type anymore. On {device}: check Accessibility access.'**
  String stoppedFailed(String device);

  /// No description provided for @lostConnection.
  ///
  /// In en, this message translates to:
  /// **'Lost the connection to {device}.'**
  String lostConnection(String device);

  /// No description provided for @unreachable.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer. On {device}: open Ferret.'**
  String unreachable(String device);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @controllingTitle.
  ///
  /// In en, this message translates to:
  /// **'Controlling {device}'**
  String controllingTitle(String device);

  /// No description provided for @controllingBody.
  ///
  /// In en, this message translates to:
  /// **'This phone is its touchpad.'**
  String get controllingBody;

  /// No description provided for @openTouchpad.
  ///
  /// In en, this message translates to:
  /// **'Open touchpad'**
  String get openTouchpad;

  /// No description provided for @healthAsksFirst.
  ///
  /// In en, this message translates to:
  /// **'Asks on {device} first'**
  String healthAsksFirst(String device);

  /// No description provided for @healthAlways.
  ///
  /// In en, this message translates to:
  /// **'Allowed on {device} without asking'**
  String healthAlways(String device);

  /// No description provided for @healthControlling.
  ///
  /// In en, this message translates to:
  /// **'Controlling {device} now'**
  String healthControlling(String device);

  /// No description provided for @healthNeedsPermissionHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret → Settings → Control and click Allow access.'**
  String healthNeedsPermissionHelp(String device);

  /// No description provided for @healthUnsupportedHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret → Settings → Control to see what it needs.'**
  String healthUnsupportedHelp(String device);

  /// No description provided for @healthTurnedOffHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret → Settings → Control and turn on Let my phones control this computer.'**
  String healthTurnedOffHelp(String device);

  /// No description provided for @healthVersion.
  ///
  /// In en, this message translates to:
  /// **'Needs a Ferret update on {device}'**
  String healthVersion(String device);

  /// No description provided for @healthVersionHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}: update Ferret.'**
  String healthVersionHelp(String device);

  /// No description provided for @healthNotAnswering.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer last time'**
  String healthNotAnswering(String device);

  /// No description provided for @healthNotAnsweringHelp.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret.'**
  String healthNotAnsweringHelp(String device);

  /// host is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Asks before it controls {host, select, mac{this Mac} windows{this PC} other{this computer}}'**
  String healthHostAsks(String host);

  /// host is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'May control {host, select, mac{this Mac} windows{this PC} other{this computer}} without asking'**
  String healthHostAlways(String host);

  /// host is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Controlling {host, select, mac{this Mac} windows{this PC} other{this computer}} now'**
  String healthHostControlling(String host);

  /// host is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Off on {host, select, mac{this Mac} windows{this PC} other{this computer}}'**
  String healthHostOff(String host);

  /// No description provided for @healthHostOffHelp.
  ///
  /// In en, this message translates to:
  /// **'Open Settings → Control and turn on Let my phones control this computer.'**
  String get healthHostOffHelp;

  /// host is mac, windows or linux.
  ///
  /// In en, this message translates to:
  /// **'Needs Accessibility access on {host, select, mac{this Mac} windows{this PC} other{this computer}}'**
  String healthHostNeedsAccess(String host);

  /// No description provided for @healthHostNeedsAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'Open Settings → Control and click Allow access.'**
  String get healthHostNeedsAccessHelp;

  /// No description provided for @healthHostUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be controlled yet'**
  String get healthHostUnavailable;

  /// No description provided for @healthHostUnavailableHelp.
  ///
  /// In en, this message translates to:
  /// **'Open Settings → Control to see what it needs.'**
  String get healthHostUnavailableHelp;

  /// No description provided for @healthNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'Needs Accessibility access on {device}'**
  String healthNeedsPermission(String device);

  /// No description provided for @healthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t be controlled'**
  String healthUnsupported(String device);

  /// No description provided for @healthTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Off on {device}'**
  String healthTurnedOff(String device);
}

class _RemoteInputLocalizationsDelegate
    extends LocalizationsDelegate<RemoteInputLocalizations> {
  const _RemoteInputLocalizationsDelegate();

  @override
  Future<RemoteInputLocalizations> load(Locale locale) {
    return SynchronousFuture<RemoteInputLocalizations>(
      lookupRemoteInputLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_RemoteInputLocalizationsDelegate old) => false;
}

RemoteInputLocalizations lookupRemoteInputLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return RemoteInputLocalizationsEn();
  }

  throw FlutterError(
    'RemoteInputLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
