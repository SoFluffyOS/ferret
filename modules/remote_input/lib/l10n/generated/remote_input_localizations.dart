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
  /// **'Remote input'**
  String get title;

  /// No description provided for @useAsTouchpad.
  ///
  /// In en, this message translates to:
  /// **'Use as touchpad'**
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
  /// **'Always'**
  String get allowAlways;

  /// No description provided for @dontAllow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t allow'**
  String get dontAllow;

  /// No description provided for @controlledBy.
  ///
  /// In en, this message translates to:
  /// **'Controlled by {device}'**
  String controlledBy(String device);

  /// No description provided for @controlledSince.
  ///
  /// In en, this message translates to:
  /// **'Since {time}. It can move the pointer and type.'**
  String controlledSince(String time);

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @activeNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Stop to take back control.'**
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
  /// **'Ready. Uses Accessibility access.'**
  String get statusReadyQuartz;

  /// No description provided for @statusReadySendInput.
  ///
  /// In en, this message translates to:
  /// **'Ready. Apps running as administrator can\'t be controlled.'**
  String get statusReadySendInput;

  /// No description provided for @statusReadyUinput.
  ///
  /// In en, this message translates to:
  /// **'Ready. Uses a virtual input device.'**
  String get statusReadyUinput;

  /// No description provided for @statusReadyXdotool.
  ///
  /// In en, this message translates to:
  /// **'Ready. Uses xdotool, which works on X11 only.'**
  String get statusReadyXdotool;

  /// No description provided for @statusReadyYdotool.
  ///
  /// In en, this message translates to:
  /// **'Ready. Uses ydotool.'**
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
  /// **'Ferret couldn\'t check whether it may control this computer.'**
  String get statusFailed;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @settingsAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Always allowed'**
  String get settingsAllowedTitle;

  /// No description provided for @settingsAllowedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No device yet. Pick Always when a phone asks.'**
  String get settingsAllowedEmpty;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

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
  /// **'Click Allow on {device}. Pick Always and it won\'t ask again.'**
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
  /// **'{device} needs Accessibility access first. Open Ferret on {device} to allow it.'**
  String deniedNeedsPermission(String device);

  /// No description provided for @deniedUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t be controlled yet. Open Ferret\'s settings on {device} to see why.'**
  String deniedUnsupported(String device);

  /// No description provided for @deniedTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Remote input is off on {device}. Turn it on in Ferret\'s settings there.'**
  String deniedTurnedOff(String device);

  /// No description provided for @deniedVersion.
  ///
  /// In en, this message translates to:
  /// **'{device} runs an older Ferret. Update it, then try again.'**
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
  /// **'{device} turned remote input off for this phone.'**
  String stoppedRevoked(String device);

  /// No description provided for @stoppedFailed.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t inject input anymore. Check Accessibility access there.'**
  String stoppedFailed(String device);

  /// No description provided for @lostConnection.
  ///
  /// In en, this message translates to:
  /// **'Lost the connection to {device}.'**
  String lostConnection(String device);

  /// No description provided for @unreachable.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer. Is Ferret open on it?'**
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
  /// **'Your phone is its touchpad.'**
  String get controllingBody;

  /// No description provided for @openTouchpad.
  ///
  /// In en, this message translates to:
  /// **'Open touchpad'**
  String get openTouchpad;

  /// No description provided for @healthNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'{device} needs Accessibility access for remote input'**
  String healthNeedsPermission(String device);

  /// No description provided for @healthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t be controlled'**
  String healthUnsupported(String device);

  /// No description provided for @healthTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Remote input is off on {device}'**
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
