import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'shell_localizations_en.dart';
import 'shell_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ShellLocalizations
/// returned by `ShellLocalizations.of(context)`.
///
/// Applications need to include `ShellLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/shell_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ShellLocalizations.localizationsDelegates,
///   supportedLocales: ShellLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ShellLocalizations.supportedLocales
/// property.
abstract class ShellLocalizations {
  ShellLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ShellLocalizations of(BuildContext context) {
    return Localizations.of<ShellLocalizations>(context, ShellLocalizations)!;
  }

  static const LocalizationsDelegate<ShellLocalizations> delegate =
      _ShellLocalizationsDelegate();

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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Ferret'**
  String get appName;

  /// No description provided for @homeYourDevices.
  ///
  /// In en, this message translates to:
  /// **'Your devices'**
  String get homeYourDevices;

  /// No description provided for @homeNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get homeNearby;

  /// No description provided for @homePairDevice.
  ///
  /// In en, this message translates to:
  /// **'Add a device'**
  String get homePairDevice;

  /// No description provided for @deviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get deviceConnected;

  /// No description provided for @deviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get deviceOffline;

  /// No description provided for @deviceReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get deviceReconnecting;

  /// No description provided for @deviceWeak.
  ///
  /// In en, this message translates to:
  /// **'Connected · weak connection'**
  String get deviceWeak;

  /// No description provided for @deviceNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Connected, needs attention'**
  String get deviceNeedsAttention;

  /// What a screen reader says for a green check next to a line. The four after it name the other status icons.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get spokenOk;

  /// No description provided for @spokenOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get spokenOff;

  /// No description provided for @spokenWarning.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get spokenWarning;

  /// No description provided for @spokenProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get spokenProblem;

  /// No description provided for @spokenChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get spokenChecking;

  /// No description provided for @deviceConnectsWhenOpen.
  ///
  /// In en, this message translates to:
  /// **'Connects when Ferret is open on it'**
  String get deviceConnectsWhenOpen;

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a device'**
  String get pairTitle;

  /// No description provided for @pairShowCode.
  ///
  /// In en, this message translates to:
  /// **'Pair with a QR code'**
  String get pairShowCode;

  /// No description provided for @pairEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Other ways'**
  String get pairEnterCode;

  /// No description provided for @pairIphoneBody.
  ///
  /// In en, this message translates to:
  /// **'An iPhone can\'t look for devices on the network by itself. On your computer, open Ferret and click +. Then scan the code it shows.'**
  String get pairIphoneBody;

  /// No description provided for @pairShowCodeBody.
  ///
  /// In en, this message translates to:
  /// **'On your phone, open Ferret and tap +, then Pair with a QR code.'**
  String get pairShowCodeBody;

  /// No description provided for @pairCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get pairCopyLink;

  /// No description provided for @pairLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get pairLinkCopied;

  /// No description provided for @pairExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes, plural, other{{minutes} min}}'**
  String pairExpiresIn(int minutes);

  /// No description provided for @pairNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get pairNewCode;

  /// No description provided for @pairLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste a link'**
  String get pairLinkLabel;

  /// No description provided for @pairLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a ferret://pair link'**
  String get pairLinkHint;

  /// No description provided for @pairLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a Ferret pairing link.'**
  String get pairLinkInvalid;

  /// No description provided for @pairAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address of the other device'**
  String get pairAddressLabel;

  /// No description provided for @pairAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.1.20:47640'**
  String get pairAddressHint;

  /// No description provided for @pairCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Check that your other device shows this code, then tap Pair there.'**
  String get pairCompareTitle;

  /// No description provided for @pairWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your other device…'**
  String get pairWaiting;

  /// No description provided for @pairSuccess.
  ///
  /// In en, this message translates to:
  /// **'Paired with {device}'**
  String pairSuccess(String device);

  /// No description provided for @pairFailedUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach that device. Put both on the same Wi-Fi, then try again.'**
  String get pairFailedUnreachable;

  /// No description provided for @pairFailedUnreachableIphone.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach that computer. Check that both are on the same Wi-Fi, and that Ferret may use the local network in Settings.'**
  String get pairFailedUnreachableIphone;

  /// No description provided for @pairFailedRejected.
  ///
  /// In en, this message translates to:
  /// **'Your other device said not now.'**
  String get pairFailedRejected;

  /// No description provided for @pairFailedExpired.
  ///
  /// In en, this message translates to:
  /// **'That code expired.'**
  String get pairFailedExpired;

  /// No description provided for @pairFailedBadProof.
  ///
  /// In en, this message translates to:
  /// **'The codes didn\'t match, so nothing was paired. Try once more, close to the other device.'**
  String get pairFailedBadProof;

  /// No description provided for @pairFailedWrongDevice.
  ///
  /// In en, this message translates to:
  /// **'A different device answered. Pairing stopped to keep you safe.'**
  String get pairFailedWrongDevice;

  /// No description provided for @pairFailedTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Your other device didn\'t answer.'**
  String get pairFailedTimedOut;

  /// No description provided for @pairFailedProtocol.
  ///
  /// In en, this message translates to:
  /// **'Pairing stopped before it finished. Try again.'**
  String get pairFailedProtocol;

  /// What a screen reader says for the six pairing digits, read one by one.
  ///
  /// In en, this message translates to:
  /// **'Code: {digits}'**
  String pairCodeSpoken(String digits);

  /// No description provided for @promptTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair with {device}?'**
  String promptTitle(String device);

  /// No description provided for @promptBody.
  ///
  /// In en, this message translates to:
  /// **'Pair only if {device} shows the same code.'**
  String promptBody(String device);

  /// No description provided for @promptAccept.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get promptAccept;

  /// No description provided for @promptReject.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get promptReject;

  /// On a device page, under its name. The ID is a short code like 3F2A 0718
  ///
  /// In en, this message translates to:
  /// **'Device ID {id}'**
  String deviceIdLine(String id);

  /// No description provided for @deviceActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get deviceActions;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsThisDevice;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret talks only to devices you paired, directly on your network, end-to-end encrypted. No account, no cloud, no telemetry.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit Ferret'**
  String get settingsQuit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @menuOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret'**
  String get menuOpen;

  /// No description provided for @menuOpenWindow.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret Window'**
  String get menuOpenWindow;

  /// No description provided for @homeOpenWindow.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret window'**
  String get homeOpenWindow;

  /// No description provided for @settingsDock.
  ///
  /// In en, this message translates to:
  /// **'Dock'**
  String get settingsDock;

  /// No description provided for @settingsAlwaysInDock.
  ///
  /// In en, this message translates to:
  /// **'Always show in the Dock'**
  String get settingsAlwaysInDock;

  /// No description provided for @settingsAlwaysInDockBody.
  ///
  /// In en, this message translates to:
  /// **'When off, Ferret is in the Dock only while its window is open.'**
  String get settingsAlwaysInDockBody;

  /// No description provided for @menuPair.
  ///
  /// In en, this message translates to:
  /// **'Add a Device…'**
  String get menuPair;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings…'**
  String get menuSettings;

  /// No description provided for @menuQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit Ferret'**
  String get menuQuit;

  /// No description provided for @menubarTipConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Ferret · Connected to {device}'**
  String menubarTipConnectedTo(String device);

  /// No description provided for @menubarTipConnected.
  ///
  /// In en, this message translates to:
  /// **'Ferret · {count, plural, =1{1 device connected} other{{count} devices connected}}'**
  String menubarTipConnected(int count);

  /// No description provided for @menubarTipAlone.
  ///
  /// In en, this message translates to:
  /// **'Ferret · No device connected'**
  String get menubarTipAlone;

  /// No description provided for @menubarTipSendingTo.
  ///
  /// In en, this message translates to:
  /// **'Ferret · Sending to {device}'**
  String menubarTipSendingTo(String device);

  /// No description provided for @menubarTipReceivingFrom.
  ///
  /// In en, this message translates to:
  /// **'Ferret · Receiving from {device}'**
  String menubarTipReceivingFrom(String device);

  /// No description provided for @menubarTipSending.
  ///
  /// In en, this message translates to:
  /// **'Ferret · Sending'**
  String get menubarTipSending;

  /// No description provided for @menubarTipReceiving.
  ///
  /// In en, this message translates to:
  /// **'Ferret · Receiving'**
  String get menubarTipReceiving;

  /// No description provided for @menubarTipDone.
  ///
  /// In en, this message translates to:
  /// **'Ferret · Done'**
  String get menubarTipDone;

  /// No description provided for @menubarTipPair.
  ///
  /// In en, this message translates to:
  /// **'Ferret · {device} wants to pair'**
  String menubarTipPair(String device);

  /// No description provided for @menubarTipRequest.
  ///
  /// In en, this message translates to:
  /// **'Ferret · {device} wants to send you something'**
  String menubarTipRequest(String device);

  /// No description provided for @menubarTipWaiting.
  ///
  /// In en, this message translates to:
  /// **'Ferret · {count, plural, =1{1 request is waiting for you} other{{count} requests are waiting for you}}'**
  String menubarTipWaiting(int count);

  /// No description provided for @menubarTipPaused.
  ///
  /// In en, this message translates to:
  /// **'Ferret · Paused'**
  String get menubarTipPaused;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your devices, working together'**
  String get welcomeTitle;

  /// No description provided for @welcomePrivacy.
  ///
  /// In en, this message translates to:
  /// **'No account. No cloud. Stays on your network.'**
  String get welcomePrivacy;

  /// No description provided for @welcomePlatforms.
  ///
  /// In en, this message translates to:
  /// **'Android · iPhone · Mac · Windows · Linux'**
  String get welcomePlatforms;

  /// No description provided for @deviceLastSeenJustNow.
  ///
  /// In en, this message translates to:
  /// **'Last seen just now'**
  String get deviceLastSeenJustNow;

  /// No description provided for @deviceLastSeenMinutes.
  ///
  /// In en, this message translates to:
  /// **'Last seen {minutes, plural, other{{minutes} min}} ago'**
  String deviceLastSeenMinutes(int minutes);

  /// No description provided for @deviceLastSeenHours.
  ///
  /// In en, this message translates to:
  /// **'Last seen {hours, plural, other{{hours} h}} ago'**
  String deviceLastSeenHours(int hours);

  /// No description provided for @deviceLastSeenDays.
  ///
  /// In en, this message translates to:
  /// **'Last seen {days, plural, other{{days} d}} ago'**
  String deviceLastSeenDays(int days);

  /// Button: Ferret runs again after a pause (not the Continue feature)
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @pauseOneHour.
  ///
  /// In en, this message translates to:
  /// **'Pause syncing for 1 hour'**
  String get pauseOneHour;

  /// No description provided for @pauseUntilTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Pause syncing until tomorrow'**
  String get pauseUntilTomorrow;

  /// No description provided for @pauseUntilResume.
  ///
  /// In en, this message translates to:
  /// **'Pause syncing until I resume'**
  String get pauseUntilResume;

  /// No description provided for @doctorTitle.
  ///
  /// In en, this message translates to:
  /// **'Fix connection'**
  String get doctorTitle;

  /// No description provided for @doctorIntro.
  ///
  /// In en, this message translates to:
  /// **'Checking why {device} isn\'t connected.'**
  String doctorIntro(String device);

  /// No description provided for @doctorNetworkOk.
  ///
  /// In en, this message translates to:
  /// **'{here, select, mac{This Mac} phone{This phone} tablet{This tablet} other{This computer}} is on a network'**
  String doctorNetworkOk(String here);

  /// No description provided for @doctorNetworkProblem.
  ///
  /// In en, this message translates to:
  /// **'{here, select, mac{This Mac} phone{This phone} tablet{This tablet} other{This computer}} isn\'t on a network. Connect to Wi-Fi or Ethernet.'**
  String doctorNetworkProblem(String here);

  /// No description provided for @doctorVpn.
  ///
  /// In en, this message translates to:
  /// **'A VPN is on ({name}). It can hide devices on your network. Allow local network access in the VPN, or turn it off.'**
  String doctorVpn(String name);

  /// No description provided for @doctorPort.
  ///
  /// In en, this message translates to:
  /// **'Ferret is using port {port} because the usual port was taken. That\'s fine.'**
  String doctorPort(String port);

  /// No description provided for @doctorSameNetworkOk.
  ///
  /// In en, this message translates to:
  /// **'{device} and {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} were on the same network'**
  String doctorSameNetworkOk(String device, String here);

  /// No description provided for @doctorSameNetworkWarning.
  ///
  /// In en, this message translates to:
  /// **'{device} was last seen on a different network ({address}). Put {device} and {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} on the same Wi-Fi.'**
  String doctorSameNetworkWarning(String device, String address, String here);

  /// No description provided for @doctorReachableRunning.
  ///
  /// In en, this message translates to:
  /// **'Knocking on {device}…'**
  String doctorReachableRunning(String device);

  /// No description provided for @doctorReachableOk.
  ///
  /// In en, this message translates to:
  /// **'{device} answered'**
  String doctorReachableOk(String device);

  /// No description provided for @doctorReachableProblem.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t answering.'**
  String doctorReachableProblem(String device);

  /// No description provided for @doctorAcceptedRunning.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get doctorAcceptedRunning;

  /// No description provided for @doctorAcceptedOk.
  ///
  /// In en, this message translates to:
  /// **'Connected. All good.'**
  String get doctorAcceptedOk;

  /// No description provided for @doctorAcceptedProblem.
  ///
  /// In en, this message translates to:
  /// **'{device} answered but doesn\'t know {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} any more. It may have been reset or reinstalled. Pair them again.'**
  String doctorAcceptedProblem(String device, String here);

  /// No description provided for @doctorFixTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get doctorFixTryAgain;

  /// No description provided for @doctorFixConnectByAddress.
  ///
  /// In en, this message translates to:
  /// **'Connect by address'**
  String get doctorFixConnectByAddress;

  /// No description provided for @doctorFixPairAgain.
  ///
  /// In en, this message translates to:
  /// **'Pair again'**
  String get doctorFixPairAgain;

  /// No description provided for @doctorFixCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get doctorFixCopy;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect by address'**
  String get connectTitle;

  /// No description provided for @connectBody.
  ///
  /// In en, this message translates to:
  /// **'On the other device, open Ferret, then Settings and Advanced. Type the address it shows.'**
  String get connectBody;

  /// No description provided for @stayTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay connected'**
  String get stayTitle;

  /// No description provided for @stayBody.
  ///
  /// In en, this message translates to:
  /// **'Android stops apps in the background to save battery. These steps keep Ferret connected. It uses about 1% battery a day.'**
  String get stayBody;

  /// No description provided for @stayNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow Ferret\'s notification, so Android lets it keep running.'**
  String get stayNotifications;

  /// No description provided for @stayNotificationsFix.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get stayNotificationsFix;

  /// No description provided for @stayBattery.
  ///
  /// In en, this message translates to:
  /// **'Android may stop Ferret in the background. Let it keep running.'**
  String get stayBattery;

  /// No description provided for @stayBatteryFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get stayBatteryFix;

  /// No description provided for @stayRestricted.
  ///
  /// In en, this message translates to:
  /// **'Battery use for Ferret is set to Restricted, so Android stops Ferret each time you leave the app.'**
  String get stayRestricted;

  /// No description provided for @stayRestrictedSteps.
  ///
  /// In en, this message translates to:
  /// **'Open App battery usage and choose Unrestricted.'**
  String get stayRestrictedSteps;

  /// No description provided for @stayRestrictedFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get stayRestrictedFix;

  /// No description provided for @stayStepsXiaomi.
  ///
  /// In en, this message translates to:
  /// **'Settings → Apps → Manage apps → Ferret: turn on Autostart and set Battery saver to No restrictions.'**
  String get stayStepsXiaomi;

  /// No description provided for @stayStepsSamsung.
  ///
  /// In en, this message translates to:
  /// **'Settings → Battery → Background usage limits → Never sleeping apps: add Ferret.'**
  String get stayStepsSamsung;

  /// No description provided for @stayStepsOneplus.
  ///
  /// In en, this message translates to:
  /// **'Settings → Apps → Ferret → Battery usage: turn on Allow background activity. Then lock Ferret in the recent apps view.'**
  String get stayStepsOneplus;

  /// No description provided for @stayStepsHuawei.
  ///
  /// In en, this message translates to:
  /// **'Settings → Battery → App launch → Ferret: turn off Manage automatically and keep all three switches on.'**
  String get stayStepsHuawei;

  /// No description provided for @stayStepsOppo.
  ///
  /// In en, this message translates to:
  /// **'Settings → Apps → Ferret → Battery usage: turn on Allow background activity and Allow auto launch.'**
  String get stayStepsOppo;

  /// No description provided for @stayStepsVivo.
  ///
  /// In en, this message translates to:
  /// **'Settings → Battery → Background power consumption management → Ferret: allow it. Turn on Autostart for Ferret too.'**
  String get stayStepsVivo;

  /// No description provided for @stayMaker.
  ///
  /// In en, this message translates to:
  /// **'Your {maker} phone has its own battery saver too. Allow Ferret there.'**
  String stayMaker(String maker);

  /// No description provided for @stayMakerFix.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get stayMakerFix;

  /// No description provided for @stayStops.
  ///
  /// In en, this message translates to:
  /// **'Android stopped Ferret {count, plural, =1{once} other{{count} times}} today.'**
  String stayStops(int count);

  /// No description provided for @stayTile.
  ///
  /// In en, this message translates to:
  /// **'Add the Ferret tile to Quick Settings to send your clipboard in one tap.'**
  String get stayTile;

  /// No description provided for @stayTileFix.
  ///
  /// In en, this message translates to:
  /// **'Add tile'**
  String get stayTileFix;

  /// device is this phone's own name, such as Pixel 7.
  ///
  /// In en, this message translates to:
  /// **'Start Ferret when {device} restarts? Otherwise it reconnects only when you open it.'**
  String stayBootAsk(String device);

  /// No description provided for @stayBootYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get stayBootYes;

  /// No description provided for @stayBootNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get stayBootNotNow;

  /// No description provided for @settingsBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get settingsBackground;

  /// No description provided for @settingsKeepRunning.
  ///
  /// In en, this message translates to:
  /// **'Keep running in the background'**
  String get settingsKeepRunning;

  /// No description provided for @settingsKeepRunningBody.
  ///
  /// In en, this message translates to:
  /// **'Stays connected when Ferret is closed. Shows a quiet notification.'**
  String get settingsKeepRunningBody;

  /// No description provided for @settingsStartOnBoot.
  ///
  /// In en, this message translates to:
  /// **'Start when the phone starts'**
  String get settingsStartOnBoot;

  /// No description provided for @dropTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Send files to…} =1{Send a file to…} other{Send {count} files to…}}'**
  String dropTitle(int count);

  /// No description provided for @dropTileDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop to send'**
  String get dropTileDrop;

  /// No description provided for @dropTilePick.
  ///
  /// In en, this message translates to:
  /// **'Send here'**
  String get dropTilePick;

  /// No description provided for @dropTileOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get dropTileOffline;

  /// No description provided for @dropAllDevices.
  ///
  /// In en, this message translates to:
  /// **'All my devices'**
  String get dropAllDevices;

  /// No description provided for @dropNobody.
  ///
  /// In en, this message translates to:
  /// **'No device to send to'**
  String get dropNobody;

  /// No description provided for @dropNobodyDetail.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret on your other device first.'**
  String get dropNobodyDetail;

  /// No description provided for @dropSendingTo.
  ///
  /// In en, this message translates to:
  /// **'Sending to {name}'**
  String dropSendingTo(String name);

  /// No description provided for @dropSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name}'**
  String dropSentTo(String name);

  /// No description provided for @dropFailedTo.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send to {name}'**
  String dropFailedTo(String name);

  /// No description provided for @dropFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'The files weren\'t sent. Try again in a moment.'**
  String get dropFailedDetail;

  /// No description provided for @dropAllDevicesName.
  ///
  /// In en, this message translates to:
  /// **'all my devices'**
  String get dropAllDevicesName;

  /// No description provided for @dropFolderCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 folder} other{{count} folders}}'**
  String dropFolderCount(int count);

  /// What was dropped, e.g. "2 files and 1 folder".
  ///
  /// In en, this message translates to:
  /// **'{files} and {folders}'**
  String dropFilesAndFolders(String files, String folders);

  /// No description provided for @dropFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String dropFileCount(int count);

  /// No description provided for @dropTitleText.
  ///
  /// In en, this message translates to:
  /// **'Send text to…'**
  String get dropTitleText;

  /// No description provided for @dropTitleLink.
  ///
  /// In en, this message translates to:
  /// **'Open link on…'**
  String get dropTitleLink;

  /// No description provided for @dropKindText.
  ///
  /// In en, this message translates to:
  /// **'Text, to its clipboard'**
  String get dropKindText;

  /// No description provided for @dropKindLink.
  ///
  /// In en, this message translates to:
  /// **'Link, opens there'**
  String get dropKindLink;

  /// No description provided for @dropTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dropTryAgain;

  /// No description provided for @dropClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dropClose;

  /// No description provided for @dropCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dropCancel;

  /// On a device row or the window's pane while files are dragged over it
  ///
  /// In en, this message translates to:
  /// **'Send to {name}'**
  String dropSendTo(String name);

  /// On the window's pane while files are dragged over it and several devices are connected
  ///
  /// In en, this message translates to:
  /// **'Send to all {count, plural, other{{count} devices}}'**
  String dropSendToAll(int count);

  /// No description provided for @dropDeviceOffline.
  ///
  /// In en, this message translates to:
  /// **'{name} is offline'**
  String dropDeviceOffline(String name);

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the code'**
  String get scanTitle;

  /// No description provided for @scanBody.
  ///
  /// In en, this message translates to:
  /// **'On your computer, open Ferret and choose Pair with a QR code. Then point your camera at it.'**
  String get scanBody;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan the code on your computer'**
  String get scanButton;

  /// No description provided for @scanNotFerret.
  ///
  /// In en, this message translates to:
  /// **'That\'s not a Ferret code. On your computer, open Ferret and tap +, then Pair with a QR code.'**
  String get scanNotFerret;

  /// Title of the Home card that suggests features to turn on
  ///
  /// In en, this message translates to:
  /// **'Do more'**
  String get offersTitle;

  /// No description provided for @offersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Extras you can turn on. All optional.'**
  String get offersSubtitle;

  /// No description provided for @onboardNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get onboardNameLabel;

  /// No description provided for @settingsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get settingsRename;

  /// No description provided for @settingsRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this device'**
  String get settingsRenameTitle;

  /// Under this device name in Settings, when Ferret runs in several OS user accounts on one computer
  ///
  /// In en, this message translates to:
  /// **'Other accounts on this computer use Ferret too. Each one has its own devices.'**
  String get thisDeviceShared;

  /// No description provided for @thisDeviceOtherPort.
  ///
  /// In en, this message translates to:
  /// **'Listening on port {port}: another account has {usual}.'**
  String thisDeviceOtherPort(String port, String usual);

  /// Body of a notice whose content is hidden: previews are off for that device, or the screen is locked
  ///
  /// In en, this message translates to:
  /// **'Open Ferret to see it.'**
  String get privateCoverBody;

  /// Second line of an Activity line whose content is hidden because previews are off for that device
  ///
  /// In en, this message translates to:
  /// **'Hidden on this computer'**
  String get privateCoverDetail;

  /// No description provided for @previewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Show previews on this computer'**
  String get previewsTitle;

  /// No description provided for @previewsBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications, texts, callers and copied text from {device} show on this screen. Off, Ferret only says that something arrived. They always hide while the screen is locked or another account is in front.'**
  String previewsBody(String device);

  /// Under the previews switch, on a computer several OS accounts run Ferret on, before the person chose
  ///
  /// In en, this message translates to:
  /// **'Off at first here, because other accounts on this computer use Ferret.'**
  String get previewsSharedDefault;

  /// No description provided for @settingsAddress.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String settingsAddress(String address);

  /// No description provided for @settingsAddressHint.
  ///
  /// In en, this message translates to:
  /// **'If another device can\'t find this one: on it, open Add a device, then Other ways, and type this address.'**
  String get settingsAddressHint;

  /// No description provided for @deviceWhyLong.
  ///
  /// In en, this message translates to:
  /// **'Why isn\'t it connecting?'**
  String get deviceWhyLong;

  /// No description provided for @deviceWhatWorks.
  ///
  /// In en, this message translates to:
  /// **'What works with {device}'**
  String deviceWhatWorks(String device);

  /// No description provided for @deviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get deviceDetails;

  /// No description provided for @deviceForget.
  ///
  /// In en, this message translates to:
  /// **'Forget {device}'**
  String deviceForget(String device);

  /// No description provided for @deviceForgetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget {device}?'**
  String deviceForgetConfirmTitle(String device);

  /// No description provided for @deviceForgetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{device} and {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} forget each other. You can pair them again any time.'**
  String deviceForgetConfirmBody(String device, String here);

  /// No description provided for @doctorTryAgainPrimary.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get doctorTryAgainPrimary;

  /// No description provided for @doctorNotAnsweringSteps.
  ///
  /// In en, this message translates to:
  /// **'Try this:\n1. On {device}, open Ferret.\n2. Put {device} and {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} on the same Wi-Fi.\n3. Guest and office Wi-Fi often keep devices apart. Try your home Wi-Fi or a phone hotspot.'**
  String doctorNotAnsweringSteps(String device, String here);

  /// No description provided for @nearbyLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking…'**
  String get nearbyLooking;

  /// No description provided for @nearbyNone.
  ///
  /// In en, this message translates to:
  /// **'No devices found yet.'**
  String get nearbyNone;

  /// No description provided for @nearbyLookAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get nearbyLookAgain;

  /// No description provided for @nearbyPair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get nearbyPair;

  /// No description provided for @nearbyConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {device}…'**
  String nearbyConnecting(String device);

  /// No description provided for @nearbyCheckCode.
  ///
  /// In en, this message translates to:
  /// **'Check that {device} shows this code.'**
  String nearbyCheckCode(String device);

  /// No description provided for @nearbyTheyMatch.
  ///
  /// In en, this message translates to:
  /// **'They match'**
  String get nearbyTheyMatch;

  /// No description provided for @nearbyTapThere.
  ///
  /// In en, this message translates to:
  /// **'On {device}, tap Pair.'**
  String nearbyTapThere(String device);

  /// No description provided for @nearbyWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {device}…'**
  String nearbyWaiting(String device);

  /// No description provided for @nearbyTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get nearbyTryAgain;

  /// No description provided for @nearbyNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer.'**
  String nearbyNoAnswer(String device);

  /// No description provided for @nearbyNotNow.
  ///
  /// In en, this message translates to:
  /// **'{device} said not now.'**
  String nearbyNotNow(String device);

  /// No description provided for @nearbyUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach {device}. Are both on the same Wi-Fi?'**
  String nearbyUnreachable(String device);

  /// No description provided for @nearbyBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ferret can\'t look for your devices'**
  String get nearbyBlockedTitle;

  /// No description provided for @nearbyBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Your system needs your OK. Allow Ferret under Privacy & Security, Local Network.'**
  String get nearbyBlockedBody;

  /// No description provided for @nearbyOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get nearbyOpenSettings;

  /// No description provided for @pairCantSeeSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Open Ferret on the other device.\n2. Put both on the same Wi-Fi.\n3. Still nothing? Check my network tells you why.'**
  String get pairCantSeeSteps;

  /// No description provided for @promptAlsoOne.
  ///
  /// In en, this message translates to:
  /// **'You\'ll also be connected to {first}.'**
  String promptAlsoOne(String first);

  /// No description provided for @promptAlsoTwo.
  ///
  /// In en, this message translates to:
  /// **'You\'ll also be connected to {first} and {second}.'**
  String promptAlsoTwo(String first, String second);

  /// No description provided for @promptAlsoMore.
  ///
  /// In en, this message translates to:
  /// **'You\'ll also be connected to {first}, {second} and {count, plural, other{{count} more}}.'**
  String promptAlsoMore(String first, String second, int count);

  /// No description provided for @promptSecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, other{{seconds} s}}'**
  String promptSecondsLeft(int seconds);

  /// No description provided for @promptNotice.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to pair'**
  String promptNotice(String device);

  /// No description provided for @promptNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret to compare the code.'**
  String get promptNoticeBody;

  /// No description provided for @joinedNotice.
  ///
  /// In en, this message translates to:
  /// **'{device} joined your devices'**
  String joinedNotice(String device);

  /// No description provided for @joinedNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Added by {introducer}'**
  String joinedNoticeBody(String introducer);

  /// No description provided for @joinedBanner.
  ///
  /// In en, this message translates to:
  /// **'{device} joined your devices (added by {introducer})'**
  String joinedBanner(String device, String introducer);

  /// No description provided for @joinedUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get joinedUndo;

  /// No description provided for @joinedKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get joinedKeep;

  /// No description provided for @devicePairedThrough.
  ///
  /// In en, this message translates to:
  /// **'Paired through {device}'**
  String devicePairedThrough(String device);

  /// No description provided for @deviceForgetScopeBody.
  ///
  /// In en, this message translates to:
  /// **'{device} is connected to your other devices too.'**
  String deviceForgetScopeBody(String device);

  /// No description provided for @deviceForgetEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Remove from all my devices'**
  String get deviceForgetEverywhere;

  /// No description provided for @deviceForgetHere.
  ///
  /// In en, this message translates to:
  /// **'Forget on {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} only'**
  String deviceForgetHere(String here);

  /// No description provided for @settingsSharePairings.
  ///
  /// In en, this message translates to:
  /// **'Pair once for all my devices'**
  String get settingsSharePairings;

  /// No description provided for @settingsSharePairingsBody.
  ///
  /// In en, this message translates to:
  /// **'A device you pair here joins all your devices. Remove it once and it leaves them all.'**
  String get settingsSharePairingsBody;

  /// No description provided for @doctorIsolated.
  ///
  /// In en, this message translates to:
  /// **'This network keeps devices apart. {here, select, mac{This Mac} phone{This phone} tablet{This tablet} other{This computer}} reaches the router but not {device}. Café, hotel, campus and guest Wi-Fi often do this. Put both on your phone\'s hotspot or a home network.'**
  String doctorIsolated(String device, String here);

  /// No description provided for @doctorIsolatedMaybe.
  ///
  /// In en, this message translates to:
  /// **'Ferret hasn\'t heard any other device on this network. If the other device is on the same Wi-Fi, this network may keep devices apart, as café, hotel and guest Wi-Fi often do. Put both on your phone\'s hotspot or a home network.'**
  String get doctorIsolatedMaybe;

  /// No description provided for @doctorNothingWrong.
  ///
  /// In en, this message translates to:
  /// **'Everything looks right on {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}}. On {device}, open Ferret.'**
  String doctorNothingWrong(String here, String device);

  /// No description provided for @doctorNetworkIntro.
  ///
  /// In en, this message translates to:
  /// **'Checking the network on {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}}.'**
  String doctorNetworkIntro(String here);

  /// No description provided for @doctorNetworkAllGood.
  ///
  /// In en, this message translates to:
  /// **'Everything looks right on {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}}. Open Ferret on your other device, on the same Wi-Fi.'**
  String doctorNetworkAllGood(String here);

  /// No description provided for @connectAction.
  ///
  /// In en, this message translates to:
  /// **'Try this address'**
  String get connectAction;

  /// No description provided for @settingsGroupClipboard.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get settingsGroupClipboard;

  /// No description provided for @settingsGroupFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get settingsGroupFiles;

  /// No description provided for @settingsGroupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue & media'**
  String get settingsGroupContinue;

  /// No description provided for @settingsGroupFromPhone.
  ///
  /// In en, this message translates to:
  /// **'From your phone'**
  String get settingsGroupFromPhone;

  /// No description provided for @settingsGroupToComputer.
  ///
  /// In en, this message translates to:
  /// **'To your computer'**
  String get settingsGroupToComputer;

  /// No description provided for @settingsGroupControl.
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get settingsGroupControl;

  /// No description provided for @settingsGroupOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Other apps'**
  String get settingsGroupOtherApps;

  /// No description provided for @settingsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsOn;

  /// No description provided for @settingsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOff;

  /// On a Settings row: how many of its switches are on, "3 of 5 on"
  ///
  /// In en, this message translates to:
  /// **'{on} of {total} on'**
  String settingsCountOn(int on, int total);

  /// Settings row value: the names of the features that are on, "Clipboard, Files on"
  ///
  /// In en, this message translates to:
  /// **'{names} on'**
  String settingsNamedOn(String names);

  /// No description provided for @settingsNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get settingsNeedsAttention;

  /// No description provided for @settingsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvanced;

  /// Settings → Advanced: the language Ferret shows
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// The default choice for Language: follow the language of the operating system
  ///
  /// In en, this message translates to:
  /// **'Same as the system'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'Menus, the tray icon and notifications switch the next time Ferret starts.'**
  String get settingsLanguageNote;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About · Privacy'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Ferret {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsLicense.
  ///
  /// In en, this message translates to:
  /// **'Free software under GPL-3.0. The protocol is open too, under MIT.'**
  String get settingsLicense;

  /// Settings, About: a row that opens the owner's GitHub Sponsors page in the browser. Never shown as a popup or reminder.
  ///
  /// In en, this message translates to:
  /// **'Sponsor Ferret'**
  String get settingsSponsor;

  /// No description provided for @settingsSponsorDetail.
  ///
  /// In en, this message translates to:
  /// **'Ferret is free. If it saves you time, you can sponsor its work on GitHub.'**
  String get settingsSponsorDetail;

  /// Settings, About: a quiet line at the bottom, followed by the settingsSponsorLink link and a heart
  ///
  /// In en, this message translates to:
  /// **'Ferret is free and open source.'**
  String get settingsOpenSource;

  /// No description provided for @settingsSponsorLink.
  ///
  /// In en, this message translates to:
  /// **'Sponsor'**
  String get settingsSponsorLink;

  /// No description provided for @settingsDeviceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get settingsDeviceIdLabel;

  /// No description provided for @settingsAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get settingsAddressLabel;

  /// No description provided for @settingsCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check my network'**
  String get settingsCheckNetwork;

  /// No description provided for @settingsNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing to set here yet. Pair a device first.'**
  String get settingsNothingHere;

  /// No description provided for @settingsShortcutTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret from anywhere'**
  String get settingsShortcutTitle;

  /// No description provided for @settingsShortcutBody.
  ///
  /// In en, this message translates to:
  /// **'Press these keys in any app to open or close Ferret\'s menu.'**
  String get settingsShortcutBody;

  /// No description provided for @settingsShortcutOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsShortcutOff;

  /// No description provided for @settingsShortcutChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get settingsShortcutChange;

  /// No description provided for @settingsShortcutTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get settingsShortcutTurnOff;

  /// No description provided for @settingsShortcutTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get settingsShortcutTurnOn;

  /// No description provided for @settingsShortcutRecording.
  ///
  /// In en, this message translates to:
  /// **'Press the new keys. Esc cancels.'**
  String get settingsShortcutRecording;

  /// No description provided for @settingsShortcutTaken.
  ///
  /// In en, this message translates to:
  /// **'macOS didn\'t take these keys. Try others.'**
  String get settingsShortcutTaken;

  /// Header above the list of features this device is allowed to use: "Pixel 7 may"
  ///
  /// In en, this message translates to:
  /// **'{device} may'**
  String deviceMay(String device);

  /// Link on a health row that opens the steps to fix it
  ///
  /// In en, this message translates to:
  /// **'How?'**
  String get deviceHow;

  /// No description provided for @deviceFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get deviceFix;

  /// date is a full date, such as Nov 3, 2026
  ///
  /// In en, this message translates to:
  /// **'Paired on {date}'**
  String devicePairedOn(String date);

  /// No description provided for @deviceNothingWorks.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet. Keep Ferret open on {device}.'**
  String deviceNothingWorks(String device);

  /// No description provided for @addDontSee.
  ///
  /// In en, this message translates to:
  /// **'Don\'t see it?'**
  String get addDontSee;

  /// No description provided for @addShowsAs.
  ///
  /// In en, this message translates to:
  /// **'Shows as {name}'**
  String addShowsAs(String name);

  /// No description provided for @qrScanEnough.
  ///
  /// In en, this message translates to:
  /// **'Scanning is enough. No code to compare.'**
  String get qrScanEnough;

  /// No description provided for @qrWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your phone…'**
  String get qrWaiting;

  /// No description provided for @otherShowQr.
  ///
  /// In en, this message translates to:
  /// **'Show a QR code'**
  String get otherShowQr;

  /// No description provided for @otherLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'With a link'**
  String get otherLinkTitle;

  /// No description provided for @otherLinkBody.
  ///
  /// In en, this message translates to:
  /// **'Copy this device\'s link and open it on the other one, or paste the other one\'s link here.'**
  String get otherLinkBody;

  /// No description provided for @otherAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'With an address'**
  String get otherAddressTitle;

  /// No description provided for @otherAddressBody.
  ///
  /// In en, this message translates to:
  /// **'For networks that hide devices from each other. The address is in Ferret\'s Settings, under Advanced, on the other device.'**
  String get otherAddressBody;

  /// No description provided for @otherPairLink.
  ///
  /// In en, this message translates to:
  /// **'Pair with link'**
  String get otherPairLink;

  /// No description provided for @otherPairAddress.
  ///
  /// In en, this message translates to:
  /// **'Pair with address'**
  String get otherPairAddress;

  /// Button that opens a menu with more actions (overflow menu)
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get homeMore;

  /// No description provided for @homeStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get homeStatusPaused;

  /// No description provided for @deviceAttention.
  ///
  /// In en, this message translates to:
  /// **'Connected · {feature}: needs attention'**
  String deviceAttention(String feature);

  /// No description provided for @devicesOffline.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} offline}}'**
  String devicesOffline(int count);

  /// Button that shows the offline devices hidden under a summary line
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get devicesShow;

  /// No description provided for @devicesPin.
  ///
  /// In en, this message translates to:
  /// **'Pin to Top'**
  String get devicesPin;

  /// No description provided for @devicesUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get devicesUnpin;

  /// Read by a screen reader for the small pin next to a pinned device's name.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get devicePinned;

  /// Under Home's device list: offline devices nobody has seen for a month, offered for removal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 not seen in 30 days} other{{count} not seen in 30 days}}'**
  String devicesStale(int count);

  /// No description provided for @devicesStaleReview.
  ///
  /// In en, this message translates to:
  /// **'Remove…'**
  String get devicesStaleReview;

  /// No description provided for @devicesStaleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {names} from {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}}?'**
  String devicesStaleConfirm(String names, String here);

  /// No description provided for @devicesStaleConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Not seen in 30 days. Your other devices keep them, and you can pair them again any time.'**
  String get devicesStaleConfirmBody;

  /// No description provided for @devicesStaleRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get devicesStaleRemove;

  /// No description provided for @deviceRename.
  ///
  /// In en, this message translates to:
  /// **'Rename…'**
  String get deviceRename;

  /// No description provided for @deviceRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name on {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}}'**
  String deviceRenameTitle(String here);

  /// No description provided for @deviceRenameBody.
  ///
  /// In en, this message translates to:
  /// **'Only {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} uses this name. {device} keeps its own.'**
  String deviceRenameBody(String here, String device);

  /// No description provided for @deviceRenameSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get deviceRenameSave;

  /// No description provided for @deviceRenameReset.
  ///
  /// In en, this message translates to:
  /// **'Use its own name'**
  String get deviceRenameReset;

  /// No description provided for @deviceSameName.
  ///
  /// In en, this message translates to:
  /// **'Another of your devices is also called {name}. Give this one a name you\'ll recognise.'**
  String deviceSameName(String name);

  /// On a device page with a nickname: the name the device gives itself
  ///
  /// In en, this message translates to:
  /// **'Calls itself {name}'**
  String deviceOwnName(String name);

  /// No description provided for @activityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityFilterAll;

  /// No description provided for @joinedManyNotice.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 device joined your devices} other{{count} devices joined your devices}}'**
  String joinedManyNotice(int count);

  /// No description provided for @joinedManyBanner.
  ///
  /// In en, this message translates to:
  /// **'{names} joined your devices'**
  String joinedManyBanner(String names);

  /// No description provided for @joinedManyAddedBy.
  ///
  /// In en, this message translates to:
  /// **'Added by {introducer}'**
  String joinedManyAddedBy(String introducer);

  /// No description provided for @joinedReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get joinedReview;

  /// No description provided for @joinedKeepAll.
  ///
  /// In en, this message translates to:
  /// **'Keep all'**
  String get joinedKeepAll;

  /// No description provided for @sidebarFind.
  ///
  /// In en, this message translates to:
  /// **'Find a device'**
  String get sidebarFind;

  /// No description provided for @sidebarNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No device called “{query}”'**
  String sidebarNoMatch(String query);

  /// No description provided for @dropOfflineCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 offline} other{{count} offline}}'**
  String dropOfflineCount(int count);

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Install Ferret on your other device too, and open it. It shows up here when both are on the same Wi-Fi. An iPhone pairs with a QR code instead.'**
  String get emptyBody;

  /// No description provided for @emptyBodyIphone.
  ///
  /// In en, this message translates to:
  /// **'Install Ferret on your computer too, and open it. Then scan the code it shows.'**
  String get emptyBodyIphone;

  /// No description provided for @emptyCantSee.
  ///
  /// In en, this message translates to:
  /// **'Can\'t see it?'**
  String get emptyCantSee;

  /// No description provided for @welcomeNearbyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Pair next to your other device. You only do it once.'**
  String get welcomeNearbyBody;

  /// No description provided for @nearbyNotTheOne.
  ///
  /// In en, this message translates to:
  /// **'Not the one you want? Open Ferret on your other device.'**
  String get nearbyNotTheOne;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activitySeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get activitySeeAll;

  /// No description provided for @activityDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get activityDismiss;

  /// No description provided for @activityQuickLook.
  ///
  /// In en, this message translates to:
  /// **'Quick Look'**
  String get activityQuickLook;

  /// No description provided for @needsYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get needsYouTitle;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Copy something or send a file.'**
  String get activityEmpty;

  /// Time of an Activity row that just happened
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get activityNow;

  /// How long ago, short, on an Activity row: "5 min"
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} min}}'**
  String activityMinutes(int count);

  /// How long ago, short, on an Activity row: "3 h"
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} h}}'**
  String activityHours(int count);

  /// How long ago, short, on an Activity row: "2 d"
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} d}}'**
  String activityDays(int count);

  /// No description provided for @footerDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag files onto a device to send'**
  String get footerDrag;

  /// No description provided for @footerKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep Ferret open to sync. iOS pauses it otherwise.'**
  String get footerKeepOpen;

  /// No description provided for @footerNobody.
  ///
  /// In en, this message translates to:
  /// **'Your devices are offline. Open Ferret on one to reach it.'**
  String get footerNobody;

  /// time is a clock time, such as 14:05
  ///
  /// In en, this message translates to:
  /// **'Paused until {time}'**
  String footerPausedUntil(String time);

  /// No description provided for @footerPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused until you resume'**
  String get footerPaused;

  /// No description provided for @tipCopyHere.
  ///
  /// In en, this message translates to:
  /// **'Try it: copy something here, then paste on {device}.'**
  String tipCopyHere(String device);

  /// No description provided for @tipCopyThere.
  ///
  /// In en, this message translates to:
  /// **'Try it: copy something on {device}, then paste here.'**
  String tipCopyThere(String device);

  /// No description provided for @tipDone.
  ///
  /// In en, this message translates to:
  /// **'That\'s it.'**
  String get tipDone;

  /// No description provided for @tipDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag files onto the Ferret icon in the menubar to send them.'**
  String get tipDrag;

  /// No description provided for @tipDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tipDismiss;

  /// No description provided for @tipPaste.
  ///
  /// In en, this message translates to:
  /// **'Tired of the Allow Paste question? Settings → Ferret → Paste from Other Apps → Allow'**
  String get tipPaste;

  /// No description provided for @tipPasteOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get tipPasteOpen;

  /// No description provided for @doctorFirewall.
  ///
  /// In en, this message translates to:
  /// **'Windows Firewall may be blocking Ferret.\n1. Tap Allow through firewall, then Yes when Windows asks.\n2. Try again.\nOr tap Open Windows Firewall, then Change settings, and tick Ferret.'**
  String get doctorFirewall;

  /// No description provided for @doctorFixOpenFirewall.
  ///
  /// In en, this message translates to:
  /// **'Open Windows Firewall'**
  String get doctorFixOpenFirewall;

  /// No description provided for @sidebarHide.
  ///
  /// In en, this message translates to:
  /// **'Hide sidebar'**
  String get sidebarHide;

  /// No description provided for @sidebarShow.
  ///
  /// In en, this message translates to:
  /// **'Show sidebar'**
  String get sidebarShow;

  /// No description provided for @activityPaneHide.
  ///
  /// In en, this message translates to:
  /// **'Hide Activity'**
  String get activityPaneHide;

  /// No description provided for @activityPaneShow.
  ///
  /// In en, this message translates to:
  /// **'Show Activity'**
  String get activityPaneShow;

  /// No description provided for @sectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get sectionOverview;

  /// No description provided for @windowTitleSection.
  ///
  /// In en, this message translates to:
  /// **'{device} — {section}'**
  String windowTitleSection(String device, String section);

  /// No description provided for @menuFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get menuFile;

  /// No description provided for @menuView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// No description provided for @menuDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get menuDevice;

  /// No description provided for @menuWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// No description provided for @menuSendFiles.
  ///
  /// In en, this message translates to:
  /// **'Send Files…'**
  String get menuSendFiles;

  /// No description provided for @menuSendClipboard.
  ///
  /// In en, this message translates to:
  /// **'Send Clipboard'**
  String get menuSendClipboard;

  /// Window command: asks a connected phone to take a photo for this computer (⌃⌘P).
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get menuTakePhoto;

  /// No description provided for @menuTakePhotoWith.
  ///
  /// In en, this message translates to:
  /// **'Take Photo with {device}'**
  String menuTakePhotoWith(String device);

  /// No description provided for @menuCloseWindow.
  ///
  /// In en, this message translates to:
  /// **'Close Window'**
  String get menuCloseWindow;

  /// No description provided for @menuShowSidebar.
  ///
  /// In en, this message translates to:
  /// **'Show Sidebar'**
  String get menuShowSidebar;

  /// No description provided for @menuHideSidebar.
  ///
  /// In en, this message translates to:
  /// **'Hide Sidebar'**
  String get menuHideSidebar;

  /// No description provided for @menuBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get menuBack;

  /// No description provided for @menuNextDevice.
  ///
  /// In en, this message translates to:
  /// **'Next Device'**
  String get menuNextDevice;

  /// No description provided for @menuPreviousDevice.
  ///
  /// In en, this message translates to:
  /// **'Previous Device'**
  String get menuPreviousDevice;

  /// No description provided for @menuFixConnection.
  ///
  /// In en, this message translates to:
  /// **'Fix Connection…'**
  String get menuFixConnection;

  /// Section header above what is happening right now (transfers in progress)
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get activityPaneNow;

  /// No description provided for @activityPaneRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent with {device}'**
  String activityPaneRecent(String device);

  /// No description provided for @activityPaneEmpty.
  ///
  /// In en, this message translates to:
  /// **'Things you send and receive with {device} show here.'**
  String activityPaneEmpty(String device);

  /// No description provided for @menuShowActivityPane.
  ///
  /// In en, this message translates to:
  /// **'Show Activity Pane'**
  String get menuShowActivityPane;

  /// No description provided for @menuHideActivityPane.
  ///
  /// In en, this message translates to:
  /// **'Hide Activity Pane'**
  String get menuHideActivityPane;

  /// No description provided for @menuForgetDevice.
  ///
  /// In en, this message translates to:
  /// **'Forget This Device…'**
  String get menuForgetDevice;

  /// No description provided for @activityOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get activityOpen;

  /// Above a device's section while the device is offline: what shows is what was loaded last. time is a clock time today, or a date and a time.
  ///
  /// In en, this message translates to:
  /// **'{device} is offline. Last updated {time}.'**
  String sectionOffline(String device, String time);

  /// No description provided for @sectionOfflineNoTime.
  ///
  /// In en, this message translates to:
  /// **'{device} is offline. This is what was here last.'**
  String sectionOfflineNoTime(String device);

  /// No description provided for @doctorFirewallLinux.
  ///
  /// In en, this message translates to:
  /// **'{firewall} is on, and it blocks Ferret until you let it through.\n1. Tap Copy the command.\n2. Paste it in a terminal and enter your password.\n3. Try again.'**
  String doctorFirewallLinux(String firewall);

  /// No description provided for @doctorFixCopyFirewallCommand.
  ///
  /// In en, this message translates to:
  /// **'Copy the command'**
  String get doctorFixCopyFirewallCommand;

  /// No description provided for @doctorFirewallAllowed.
  ///
  /// In en, this message translates to:
  /// **'Windows Firewall lets Ferret in on private networks. Still hidden? Make sure this network is set to Private: Settings → Network & internet → your Wi-Fi.'**
  String get doctorFirewallAllowed;

  /// No description provided for @doctorFixAllowFirewall.
  ///
  /// In en, this message translates to:
  /// **'Allow through firewall'**
  String get doctorFixAllowFirewall;

  /// No description provided for @traySendClipboard.
  ///
  /// In en, this message translates to:
  /// **'Send clipboard to my devices'**
  String get traySendClipboard;

  /// No description provided for @trayStillRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Ferret is still running'**
  String get trayStillRunningTitle;

  /// No description provided for @trayStillRunningBody.
  ///
  /// In en, this message translates to:
  /// **'Find it in the tray, next to the clock. Quit from its menu.'**
  String get trayStillRunningBody;

  /// The name of a notification category, shown in the system notification settings
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get noticeChannelTransfers;

  /// The name of a notification category, shown in the system notification settings
  ///
  /// In en, this message translates to:
  /// **'From your devices'**
  String get noticeChannelIncoming;

  /// The name of a notification category, shown in the system notification settings. Pages and media another device offers to continue here
  ///
  /// In en, this message translates to:
  /// **'Continue suggestions'**
  String get noticeChannelSuggestions;

  /// The name of a notification category, shown in the system notification settings. A device ringing so you can find it
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get noticeChannelFind;

  /// The name of a notification category, shown in the system notification settings
  ///
  /// In en, this message translates to:
  /// **'Connection problems'**
  String get noticeChannelProblems;

  /// No description provided for @settingsStartAtLogin.
  ///
  /// In en, this message translates to:
  /// **'Start Ferret when I log in'**
  String get settingsStartAtLogin;

  /// No description provided for @settingsStartAtLoginBody.
  ///
  /// In en, this message translates to:
  /// **'It starts in the tray, so your devices connect before you need them.'**
  String get settingsStartAtLoginBody;

  /// No description provided for @menuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuHelp;

  /// No description provided for @menuKeyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get menuKeyboardShortcuts;

  /// No description provided for @menuCheckNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check My Network…'**
  String get menuCheckNetwork;

  /// Help menu on a Mac and the window's ••• menu on Windows and Linux: opens the GitHub Sponsors page in the browser
  ///
  /// In en, this message translates to:
  /// **'Sponsor Ferret…'**
  String get menuSponsor;

  /// No description provided for @shortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get shortcutsTitle;

  /// No description provided for @shortcutSections.
  ///
  /// In en, this message translates to:
  /// **'Sections of the selected device'**
  String get shortcutSections;

  /// No description provided for @shortcutSidebar.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the device list'**
  String get shortcutSidebar;

  /// No description provided for @shortcutActivityPane.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the Activity pane'**
  String get shortcutActivityPane;

  /// No description provided for @accessTitle.
  ///
  /// In en, this message translates to:
  /// **'What {device} can use'**
  String accessTitle(String device);

  /// No description provided for @accessIntro.
  ///
  /// In en, this message translates to:
  /// **'{device} reaches {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} only through what\'s on here, directly on your network. Turn one off and it stops right away, on both devices.'**
  String accessIntro(String device, String here);

  /// No description provided for @accessOffline.
  ///
  /// In en, this message translates to:
  /// **'{device} is offline. What you change applies before it can use anything again.'**
  String accessOffline(String device);

  /// No description provided for @accessSummaryAll.
  ///
  /// In en, this message translates to:
  /// **'Everything on'**
  String get accessSummaryAll;

  /// No description provided for @accessSummaryNone.
  ///
  /// In en, this message translates to:
  /// **'Everything off'**
  String get accessSummaryNone;

  /// On a device page: how many features this device may not use, "2 of 10 off"
  ///
  /// In en, this message translates to:
  /// **'{off} of {total} off'**
  String accessSummarySome(int off, int total);

  /// No description provided for @accessTurnAllOff.
  ///
  /// In en, this message translates to:
  /// **'Turn everything off'**
  String get accessTurnAllOff;

  /// No description provided for @accessTurnAllOn.
  ///
  /// In en, this message translates to:
  /// **'Turn everything back on'**
  String get accessTurnAllOn;

  /// No description provided for @accessForgetHint.
  ///
  /// In en, this message translates to:
  /// **'Turning everything off keeps {device} paired. To stop it connecting at all, forget it at the bottom of its page.'**
  String accessForgetHint(String device);

  /// No description provided for @accessClipboard.
  ///
  /// In en, this message translates to:
  /// **'What you copy, both ways'**
  String get accessClipboard;

  /// No description provided for @accessDrop.
  ///
  /// In en, this message translates to:
  /// **'Files and links you send, both ways'**
  String get accessDrop;

  /// No description provided for @accessNotifications.
  ///
  /// In en, this message translates to:
  /// **'A phone\'s notifications, and the replies and actions you send back'**
  String get accessNotifications;

  /// No description provided for @accessMessages.
  ///
  /// In en, this message translates to:
  /// **'A phone\'s texts and contacts\' names, and texts you send from a computer'**
  String get accessMessages;

  /// No description provided for @accessCalls.
  ///
  /// In en, this message translates to:
  /// **'Who is calling, recent calls, answering and placing calls'**
  String get accessCalls;

  /// No description provided for @accessHandoff.
  ///
  /// In en, this message translates to:
  /// **'The page or thing you were on, to continue it on the other device'**
  String get accessHandoff;

  /// No description provided for @accessMedia.
  ///
  /// In en, this message translates to:
  /// **'What\'s playing, and play, pause and skip from the other device'**
  String get accessMedia;

  /// No description provided for @accessMirroring.
  ///
  /// In en, this message translates to:
  /// **'Showing a phone\'s screen, each time only after the phone says yes'**
  String get accessMirroring;

  /// No description provided for @accessRemoteInput.
  ///
  /// In en, this message translates to:
  /// **'Moving the pointer and typing, only after you allow it'**
  String get accessRemoteInput;

  /// No description provided for @accessFind.
  ///
  /// In en, this message translates to:
  /// **'Ringing a device to find it'**
  String get accessFind;

  /// No description provided for @accessActions.
  ///
  /// In en, this message translates to:
  /// **'Sleep, restart, shut down, volume and your own actions, each only after you allow it'**
  String get accessActions;

  /// No description provided for @menubarTipControlled.
  ///
  /// In en, this message translates to:
  /// **'{device} is controlling this computer'**
  String menubarTipControlled(String device);

  /// No description provided for @menubarTipScreenSeen.
  ///
  /// In en, this message translates to:
  /// **'{device} can see this screen'**
  String menubarTipScreenSeen(String device);

  /// No description provided for @deviceUpdateThere.
  ///
  /// In en, this message translates to:
  /// **'Needs a newer Ferret'**
  String get deviceUpdateThere;

  /// No description provided for @deviceUpdateHere.
  ///
  /// In en, this message translates to:
  /// **'Update Ferret here to connect'**
  String get deviceUpdateHere;

  /// No description provided for @updateThereTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Ferret on {name}'**
  String updateThereTitle(String name);

  /// No description provided for @updateThereBody.
  ///
  /// In en, this message translates to:
  /// **'{name} has an older Ferret ({version}) that {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} can\'t talk to anymore. Update it from where you installed it, then open it once. They connect again by themselves.'**
  String updateThereBody(String name, String version, String here);

  /// No description provided for @updateHereTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Ferret on {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}}'**
  String updateHereTitle(String here);

  /// No description provided for @updateHereBody.
  ///
  /// In en, this message translates to:
  /// **'{name} has a newer Ferret that {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} can\'t talk to yet. Update Ferret here, and they connect again by themselves.'**
  String updateHereBody(String name, String here);

  /// No description provided for @updateGet.
  ///
  /// In en, this message translates to:
  /// **'Get the update'**
  String get updateGet;

  /// No description provided for @replaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Is this your new {name}?'**
  String replaceTitle(String name);

  /// old is the old device name; "since" means since the date shown just above
  ///
  /// In en, this message translates to:
  /// **'{old} hasn\'t been seen since. Replace it, and it goes from all your devices, while this one keeps its name, pin and what it may use.'**
  String replaceBody(String old);

  /// No description provided for @replaceAction.
  ///
  /// In en, this message translates to:
  /// **'Replace the old one'**
  String get replaceAction;

  /// No description provided for @replaceKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get replaceKeepBoth;

  /// No description provided for @whatsNewLine.
  ///
  /// In en, this message translates to:
  /// **'Updated to Ferret {version}'**
  String whatsNewLine(String version);

  /// No description provided for @whatsNewAction.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewAction;

  /// Settings, About: a row that brings back the one-time hints on Home
  ///
  /// In en, this message translates to:
  /// **'Show tips again'**
  String get settingsTipsAgain;

  /// No description provided for @settingsTipsAgainDetail.
  ///
  /// In en, this message translates to:
  /// **'The short hints at the top of Ferret, such as how to copy across.'**
  String get settingsTipsAgainDetail;

  /// No description provided for @settingsTipsAgainDone.
  ///
  /// In en, this message translates to:
  /// **'Tips are back, one at a time.'**
  String get settingsTipsAgainDone;

  /// Settings, About, under the privacy promise. Points at the per-device switches on each device's page
  ///
  /// In en, this message translates to:
  /// **'To choose what one device can use, open that device and look under What it can use.'**
  String get settingsPrivacyPerDevice;

  /// Status of a connected computer whose screen is locked or showing another account. Short: it sits under the device's name
  ///
  /// In en, this message translates to:
  /// **'Connected · locked'**
  String get deviceAway;

  /// No description provided for @doctorHotspot.
  ///
  /// In en, this message translates to:
  /// **'No shared Wi-Fi? Turn on {phone}\'s hotspot and join it from {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}}. Ferret works over it, and what goes between your devices uses no mobile data.'**
  String doctorHotspot(String phone, String here);

  /// No description provided for @doctorHotspotAny.
  ///
  /// In en, this message translates to:
  /// **'No shared Wi-Fi? Turn on your phone\'s hotspot and join it from {here, select, mac{this Mac} phone{your other device} tablet{this tablet} other{this computer}}. Ferret works over it, and what goes between your devices uses no mobile data.'**
  String doctorHotspotAny(String here);

  /// No description provided for @doctorHotspotHere.
  ///
  /// In en, this message translates to:
  /// **'No shared Wi-Fi? Turn on this phone\'s hotspot and join it from {device}. Ferret works over it, and what goes between your devices uses no mobile data.'**
  String doctorHotspotHere(String device);

  /// No description provided for @webcamRow.
  ///
  /// In en, this message translates to:
  /// **'Use {device} as a webcam'**
  String webcamRow(String device);

  /// No description provided for @webcamTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} as a webcam'**
  String webcamTitle(String device);

  /// No description provided for @webcamIntro.
  ///
  /// In en, this message translates to:
  /// **'Many Android phones with Android 14 or later can be a USB webcam all by themselves. No app, no driver.'**
  String get webcamIntro;

  /// No description provided for @webcamSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Plug {device} into {here, select, mac{this Mac} phone{this phone} tablet{this tablet} other{this computer}} with a USB cable.\n2. On {device}, pull down from the top and tap the USB notification.\n3. Choose Webcam.\n4. In your video app, pick the phone as the camera.'**
  String webcamSteps(String device, String here);

  /// No description provided for @webcamMissing.
  ///
  /// In en, this message translates to:
  /// **'No Webcam in that list? {device} doesn\'t have it yet. Pixel phones from the Pixel 6 on do.'**
  String webcamMissing(String device);

  /// No description provided for @webcamNotOverWifi.
  ///
  /// In en, this message translates to:
  /// **'Ferret doesn\'t send a phone\'s camera over Wi-Fi yet.'**
  String get webcamNotOverWifi;

  /// No description provided for @batteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Battery {percent}'**
  String batteryLevel(String percent);

  /// No description provided for @batteryCharging.
  ///
  /// In en, this message translates to:
  /// **'Battery {percent}, charging'**
  String batteryCharging(String percent);

  /// No description provided for @lowBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} is at {percent}%'**
  String lowBatteryTitle(String device, int percent);

  /// No description provided for @lowBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'Plug it in soon to keep it connected.'**
  String get lowBatteryBody;

  /// No description provided for @settingsLowBattery.
  ///
  /// In en, this message translates to:
  /// **'Low battery notice'**
  String get settingsLowBattery;

  /// No description provided for @settingsLowBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'Says once when one of your devices drops to 15%.'**
  String get settingsLowBatteryBody;

  /// No description provided for @vpnRow.
  ///
  /// In en, this message translates to:
  /// **'Reach away from home'**
  String get vpnRow;

  /// No description provided for @vpnTitle.
  ///
  /// In en, this message translates to:
  /// **'Reach {device} away from home'**
  String vpnTitle(String device);

  /// No description provided for @vpnIntro.
  ///
  /// In en, this message translates to:
  /// **'Not on the same Wi-Fi? If {device} and this device are both on your own VPN, such as Tailscale, ZeroTier or WireGuard, Ferret can reach it there. No Ferret account, no Ferret server: the VPN is yours.'**
  String vpnIntro(String device);

  /// No description provided for @vpnSwitch.
  ///
  /// In en, this message translates to:
  /// **'Also reach {device} over your VPN'**
  String vpnSwitch(String device);

  /// No description provided for @vpnSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Ferret tries your local network first, every time. Off, it never leaves it.'**
  String get vpnSwitchHint;

  /// No description provided for @vpnReachAt.
  ///
  /// In en, this message translates to:
  /// **'Reach at'**
  String get vpnReachAt;

  /// No description provided for @vpnReachAtHint.
  ///
  /// In en, this message translates to:
  /// **'100.101.102.103 or pixel.tail1234.ts.net'**
  String get vpnReachAtHint;

  /// No description provided for @vpnSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get vpnSaveAddress;

  /// No description provided for @vpnAddresses.
  ///
  /// In en, this message translates to:
  /// **'{device} shared its VPN addresses: {addresses}. The address above is optional.'**
  String vpnAddresses(String device, String addresses);

  /// No description provided for @vpnNoAddresses.
  ///
  /// In en, this message translates to:
  /// **'{device} hasn\'t shared its VPN addresses yet. It does the next time it connects, if it\'s on a VPN. Or type its address above.'**
  String vpnNoAddresses(String device);

  /// No description provided for @vpnSlow.
  ///
  /// In en, this message translates to:
  /// **'Large files may take longer than at home.'**
  String get vpnSlow;

  /// No description provided for @vpnPrivacy.
  ///
  /// In en, this message translates to:
  /// **'This asks {device} for its VPN addresses. {here, select, mac{This Mac\'s} phone{This phone\'s} tablet{This tablet\'s} other{This computer\'s}} own go only to devices that have this switch on for it.'**
  String vpnPrivacy(String device, String here);

  /// No description provided for @deviceReachedOverVpn.
  ///
  /// In en, this message translates to:
  /// **'Reached over your VPN'**
  String get deviceReachedOverVpn;

  /// No description provided for @doctorVpnReachOn.
  ///
  /// In en, this message translates to:
  /// **'Ferret also tries {device} over your VPN. Make sure the VPN is on, on both devices.'**
  String doctorVpnReachOn(String device);

  /// No description provided for @doctorVpnReachOff.
  ///
  /// In en, this message translates to:
  /// **'Away from home? If {device} is on your VPN too, Ferret can reach it there.'**
  String doctorVpnReachOff(String device);

  /// No description provided for @doctorFixReachOverVpn.
  ///
  /// In en, this message translates to:
  /// **'Reach over your VPN'**
  String get doctorFixReachOverVpn;
}

class _ShellLocalizationsDelegate
    extends LocalizationsDelegate<ShellLocalizations> {
  const _ShellLocalizationsDelegate();

  @override
  Future<ShellLocalizations> load(Locale locale) {
    return SynchronousFuture<ShellLocalizations>(
      lookupShellLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_ShellLocalizationsDelegate old) => false;
}

ShellLocalizations lookupShellLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ShellLocalizationsEn();
    case 'vi':
      return ShellLocalizationsVi();
  }

  throw FlutterError(
    'ShellLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
