import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'shell_localizations_en.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

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

  /// No description provided for @homeNoDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No devices yet'**
  String get homeNoDevicesTitle;

  /// No description provided for @homeNoDevicesBody.
  ///
  /// In en, this message translates to:
  /// **'Pair your phone and your computer to start passing things between them.'**
  String get homeNoDevicesBody;

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

  /// No description provided for @deviceLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String deviceLastSeen(String time);

  /// No description provided for @nearbyPairHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to pair'**
  String get nearbyPairHint;

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
  /// **'Expires in {minutes} min'**
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

  /// No description provided for @pairConnect.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pairConnect;

  /// No description provided for @pairCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Check that your other device shows this code, then tap Pair there.'**
  String get pairCompareTitle;

  /// No description provided for @pairCompareBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure {device} shows the same code, then confirm there.'**
  String pairCompareBody(String device);

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

  /// No description provided for @deviceTitleId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceTitleId;

  /// No description provided for @deviceActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get deviceActions;

  /// No description provided for @deviceUnpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get deviceUnpair;

  /// No description provided for @deviceUnpairConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpair {device}?'**
  String deviceUnpairConfirmTitle(String device);

  /// No description provided for @deviceUnpairConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Both devices forget each other. You can pair again any time.'**
  String get deviceUnpairConfirmBody;

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

  /// No description provided for @settingsDeviceId.
  ///
  /// In en, this message translates to:
  /// **'ID {id}'**
  String settingsDeviceId(String id);

  /// No description provided for @settingsPort.
  ///
  /// In en, this message translates to:
  /// **'Listening on port {port}'**
  String settingsPort(int port);

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
  /// **'Ferret · {count} devices connected'**
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

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Pair your phone and computer to pass pages, media, files and your clipboard between them.'**
  String get welcomeBody;

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
  /// **'Last seen {minutes} min ago'**
  String deviceLastSeenMinutes(int minutes);

  /// No description provided for @deviceLastSeenHours.
  ///
  /// In en, this message translates to:
  /// **'Last seen {hours} h ago'**
  String deviceLastSeenHours(int hours);

  /// No description provided for @deviceLastSeenDays.
  ///
  /// In en, this message translates to:
  /// **'Last seen {days} d ago'**
  String deviceLastSeenDays(int days);

  /// No description provided for @deviceWhy.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get deviceWhy;

  /// No description provided for @pausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ferret is paused'**
  String get pausedTitle;

  /// No description provided for @pausedUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {time}'**
  String pausedUntil(String time);

  /// No description provided for @pausedUntilResume.
  ///
  /// In en, this message translates to:
  /// **'Until you resume'**
  String get pausedUntilResume;

  /// No description provided for @resume.
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
  /// **'Pause for 1 hour'**
  String get pauseOneHour;

  /// No description provided for @pauseUntilTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Pause until tomorrow'**
  String get pauseUntilTomorrow;

  /// No description provided for @pauseUntilResume.
  ///
  /// In en, this message translates to:
  /// **'Pause until I resume'**
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
  /// **'{here} is on a network'**
  String doctorNetworkOk(String here);

  /// No description provided for @doctorNetworkProblem.
  ///
  /// In en, this message translates to:
  /// **'{here} isn\'t on a network. Connect to Wi-Fi or Ethernet.'**
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
  /// **'{device} and {here} were on the same network'**
  String doctorSameNetworkOk(String device, String here);

  /// No description provided for @doctorSameNetworkWarning.
  ///
  /// In en, this message translates to:
  /// **'{device} was last seen on a different network ({address}). Put {device} and {here} on the same Wi-Fi.'**
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
  /// **'{device} answered but doesn\'t know {here} any more. It may have been reset or reinstalled. Pair them again.'**
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

  /// No description provided for @doctorCopied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied. They contain no names or content.'**
  String get doctorCopied;

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

  /// No description provided for @featureChipOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get featureChipOff;

  /// No description provided for @settingsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get settingsPause;

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
  /// **'Let Ferret run in the background.'**
  String get stayBattery;

  /// No description provided for @stayBatteryFix.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get stayBatteryFix;

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

  /// No description provided for @dropFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String dropFileCount(int count);

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

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the code'**
  String get scanTitle;

  /// No description provided for @scanBody.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the code Ferret shows on your computer.'**
  String get scanBody;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Scan the code on your computer'**
  String get scanButton;

  /// No description provided for @scanSection.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanSection;

  /// No description provided for @scanNotFerret.
  ///
  /// In en, this message translates to:
  /// **'That\'s not a Ferret code. On your computer, open Ferret and tap +, then Pair with a QR code.'**
  String get scanNotFerret;

  /// No description provided for @offersTitle.
  ///
  /// In en, this message translates to:
  /// **'Do more'**
  String get offersTitle;

  /// No description provided for @offersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each one asks only for what it needs.'**
  String get offersSubtitle;

  /// No description provided for @onboardWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your devices, working together'**
  String get onboardWelcomeTitle;

  /// No description provided for @onboardWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret passes what you\'re doing between your phone and your computer.'**
  String get onboardWelcomeBody;

  /// No description provided for @onboardPointContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue a page or song on another device'**
  String get onboardPointContinue;

  /// No description provided for @onboardPointClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy on one, paste on the other'**
  String get onboardPointClipboard;

  /// No description provided for @onboardPointFiles.
  ///
  /// In en, this message translates to:
  /// **'Send files and photos in a second'**
  String get onboardPointFiles;

  /// No description provided for @onboardPointPhone.
  ///
  /// In en, this message translates to:
  /// **'See your phone\'s calls, texts and notifications'**
  String get onboardPointPhone;

  /// No description provided for @onboardStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardStart;

  /// No description provided for @onboardStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardStep(int step, int total);

  /// No description provided for @onboardNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name this device'**
  String get onboardNameTitle;

  /// No description provided for @onboardNameBody.
  ///
  /// In en, this message translates to:
  /// **'Your other devices will show it by this name.'**
  String get onboardNameBody;

  /// No description provided for @onboardNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get onboardNameLabel;

  /// No description provided for @onboardContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardContinue;

  /// No description provided for @onboardPairTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair your other device'**
  String get onboardPairTitle;

  /// No description provided for @onboardPairBodyComputer.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret on your phone, on the same Wi-Fi. It shows up here.'**
  String get onboardPairBodyComputer;

  /// No description provided for @onboardPairBodyPhone.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret on your computer, on the same Wi-Fi. It shows up here.'**
  String get onboardPairBodyPhone;

  /// No description provided for @onboardPairWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your other device…'**
  String get onboardPairWaiting;

  /// No description provided for @onboardPairDone.
  ///
  /// In en, this message translates to:
  /// **'Paired with {device}'**
  String onboardPairDone(String device);

  /// No description provided for @onboardShowMyCode.
  ///
  /// In en, this message translates to:
  /// **'Show my code instead'**
  String get onboardShowMyCode;

  /// No description provided for @onboardMoreWays.
  ///
  /// In en, this message translates to:
  /// **'More ways to pair'**
  String get onboardMoreWays;

  /// No description provided for @onboardLater.
  ///
  /// In en, this message translates to:
  /// **'Do this later'**
  String get onboardLater;

  /// No description provided for @onboardReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get onboardReadyTitle;

  /// No description provided for @onboardReadyBodyPaired.
  ///
  /// In en, this message translates to:
  /// **'{device} and this device are connected.'**
  String onboardReadyBodyPaired(String device);

  /// No description provided for @onboardReadyBodyLater.
  ///
  /// In en, this message translates to:
  /// **'Pair a device any time with the + button.'**
  String get onboardReadyBodyLater;

  /// No description provided for @onboardTipCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy something here, then paste it on your other device.'**
  String get onboardTipCopy;

  /// No description provided for @onboardTipDropComputer.
  ///
  /// In en, this message translates to:
  /// **'Drop files on Ferret to send them.'**
  String get onboardTipDropComputer;

  /// No description provided for @onboardTipSharePhone.
  ///
  /// In en, this message translates to:
  /// **'Use Share → Send with Ferret to send files and links.'**
  String get onboardTipSharePhone;

  /// No description provided for @onboardTipMenubar.
  ///
  /// In en, this message translates to:
  /// **'Ferret lives in the menubar. Click ⇆ at the top of the screen.'**
  String get onboardTipMenubar;

  /// No description provided for @onboardTipTray.
  ///
  /// In en, this message translates to:
  /// **'Ferret lives in the tray, next to the clock.'**
  String get onboardTipTray;

  /// No description provided for @onboardTipAndroid.
  ///
  /// In en, this message translates to:
  /// **'Ferret keeps a quiet notification so it stays connected.'**
  String get onboardTipAndroid;

  /// No description provided for @onboardTipMore.
  ///
  /// In en, this message translates to:
  /// **'Turn on more (calls, texts, notifications) from the home screen.'**
  String get onboardTipMore;

  /// No description provided for @onboardFinish.
  ///
  /// In en, this message translates to:
  /// **'Start using Ferret'**
  String get onboardFinish;

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
  /// **'{device} and {here} forget each other. You can pair them again any time.'**
  String deviceForgetConfirmBody(String device, String here);

  /// No description provided for @chipOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get chipOff;

  /// No description provided for @doctorTryAgainPrimary.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get doctorTryAgainPrimary;

  /// No description provided for @doctorNotAnsweringSteps.
  ///
  /// In en, this message translates to:
  /// **'Try this:\n1. On {device}, open Ferret.\n2. Put {device} and {here} on the same Wi-Fi.\n3. Guest and office Wi-Fi often keep devices apart. Try your home Wi-Fi or a phone hotspot.'**
  String doctorNotAnsweringSteps(String device, String here);

  /// No description provided for @pauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause Ferret?'**
  String get pauseTitle;

  /// No description provided for @pauseBody.
  ///
  /// In en, this message translates to:
  /// **'Your devices won\'t connect or sync until you resume.'**
  String get pauseBody;

  /// No description provided for @settingsConnectByHand.
  ///
  /// In en, this message translates to:
  /// **'Connect by hand'**
  String get settingsConnectByHand;

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

  /// No description provided for @pairCantSee.
  ///
  /// In en, this message translates to:
  /// **'Can\'t see your device?'**
  String get pairCantSee;

  /// No description provided for @pairCantSeeSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Open Ferret on the other device.\n2. Put both on the same Wi-Fi.'**
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
  /// **'You\'ll also be connected to {first}, {second} and {count} more.'**
  String promptAlsoMore(String first, String second, int count);

  /// No description provided for @promptSecondsLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
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
  /// **'Forget on {here} only'**
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

  /// No description provided for @doctorNothingWrong.
  ///
  /// In en, this message translates to:
  /// **'Everything looks right on {here}. On {device}, open Ferret.'**
  String doctorNothingWrong(String here, String device);

  /// No description provided for @doctorNetworkIntro.
  ///
  /// In en, this message translates to:
  /// **'Checking the network on {here}.'**
  String doctorNetworkIntro(String here);

  /// No description provided for @doctorNetworkAllGood.
  ///
  /// In en, this message translates to:
  /// **'Everything looks right on {here}. Open Ferret on your other device, on the same Wi-Fi.'**
  String doctorNetworkAllGood(String here);

  /// No description provided for @connectAction.
  ///
  /// In en, this message translates to:
  /// **'Try this address'**
  String get connectAction;

  /// No description provided for @thisMac.
  ///
  /// In en, this message translates to:
  /// **'this Mac'**
  String get thisMac;

  /// No description provided for @thisPhone.
  ///
  /// In en, this message translates to:
  /// **'this phone'**
  String get thisPhone;

  /// No description provided for @thisTablet.
  ///
  /// In en, this message translates to:
  /// **'this tablet'**
  String get thisTablet;

  /// No description provided for @thisComputer.
  ///
  /// In en, this message translates to:
  /// **'this computer'**
  String get thisComputer;

  /// No description provided for @thisMacStart.
  ///
  /// In en, this message translates to:
  /// **'This Mac'**
  String get thisMacStart;

  /// No description provided for @thisPhoneStart.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get thisPhoneStart;

  /// No description provided for @thisTabletStart.
  ///
  /// In en, this message translates to:
  /// **'This tablet'**
  String get thisTabletStart;

  /// No description provided for @thisComputerStart.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get thisComputerStart;

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

  /// No description provided for @settingsCountOn.
  ///
  /// In en, this message translates to:
  /// **'{on} of {total} on'**
  String settingsCountOn(int on, int total);

  /// No description provided for @settingsNamedOn.
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

  /// No description provided for @settingsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get settingsCopy;

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

  /// No description provided for @deviceMay.
  ///
  /// In en, this message translates to:
  /// **'{device} may'**
  String deviceMay(String device);

  /// No description provided for @deviceHow.
  ///
  /// In en, this message translates to:
  /// **'How?'**
  String get deviceHow;

  /// No description provided for @deviceFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get deviceFix;

  /// No description provided for @devicePairedOn.
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

  /// No description provided for @qrScanRow.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code'**
  String get qrScanRow;

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

  /// No description provided for @homeMore.
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
  /// **'{count} offline'**
  String devicesOffline(int count);

  /// No description provided for @devicesShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get devicesShow;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret on your other device. It shows up here when both are on the same Wi-Fi.'**
  String get emptyBody;

  /// No description provided for @emptyCantSee.
  ///
  /// In en, this message translates to:
  /// **'Can\'t see it?'**
  String get emptyCantSee;

  /// No description provided for @emptyGetFerretPhone.
  ///
  /// In en, this message translates to:
  /// **'Get Ferret for your phone'**
  String get emptyGetFerretPhone;

  /// No description provided for @emptyGetFerretComputer.
  ///
  /// In en, this message translates to:
  /// **'Get Ferret for your computer'**
  String get emptyGetFerretComputer;

  /// No description provided for @welcomeNearbyBody.
  ///
  /// In en, this message translates to:
  /// **'Pair a device near you to start.'**
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

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Copy something or send a file.'**
  String get activityEmpty;

  /// No description provided for @activityNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get activityNow;

  /// No description provided for @activityMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String activityMinutes(int count);

  /// No description provided for @activityHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String activityHours(int count);

  /// No description provided for @activityDays.
  ///
  /// In en, this message translates to:
  /// **'{count} d'**
  String activityDays(int count);

  /// No description provided for @footerDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag files onto a device to send'**
  String get footerDrag;

  /// No description provided for @footerNobody.
  ///
  /// In en, this message translates to:
  /// **'Nothing to send to right now.'**
  String get footerNobody;

  /// No description provided for @footerPausedUntil.
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_ShellLocalizationsDelegate old) => false;
}

ShellLocalizations lookupShellLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ShellLocalizationsEn();
  }

  throw FlutterError(
    'ShellLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
