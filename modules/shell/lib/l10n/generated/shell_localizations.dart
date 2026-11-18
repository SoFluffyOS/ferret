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
  /// **'Pair a device'**
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
  /// **'Pair a device'**
  String get pairTitle;

  /// No description provided for @pairShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show code'**
  String get pairShowCode;

  /// No description provided for @pairEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Use a link'**
  String get pairEnterCode;

  /// No description provided for @pairShowCodeBody.
  ///
  /// In en, this message translates to:
  /// **'On your phone, open Ferret and tap Scan the code on your computer.'**
  String get pairShowCodeBody;

  /// No description provided for @pairCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get pairCopyLink;

  /// No description provided for @pairLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
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
  /// **'Pairing link'**
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
  /// **'Connect'**
  String get pairConnect;

  /// No description provided for @pairCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare the codes'**
  String get pairCompareTitle;

  /// No description provided for @pairCompareBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure {device} shows the same code, then confirm there.'**
  String pairCompareBody(String device);

  /// No description provided for @pairWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other device…'**
  String get pairWaiting;

  /// No description provided for @pairSuccess.
  ///
  /// In en, this message translates to:
  /// **'Paired with {device}'**
  String pairSuccess(String device);

  /// No description provided for @pairFailedUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach that device. Are both on the same network?'**
  String get pairFailedUnreachable;

  /// No description provided for @pairFailedRejected.
  ///
  /// In en, this message translates to:
  /// **'The other device said no.'**
  String get pairFailedRejected;

  /// No description provided for @pairFailedExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Show a new one.'**
  String get pairFailedExpired;

  /// No description provided for @pairFailedBadProof.
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t match. Try a new one.'**
  String get pairFailedBadProof;

  /// No description provided for @pairFailedWrongDevice.
  ///
  /// In en, this message translates to:
  /// **'A different device answered. Pairing stopped to keep you safe.'**
  String get pairFailedWrongDevice;

  /// No description provided for @pairFailedTimedOut.
  ///
  /// In en, this message translates to:
  /// **'No answer in time.'**
  String get pairFailedTimedOut;

  /// No description provided for @pairFailedProtocol.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while pairing.'**
  String get pairFailedProtocol;

  /// No description provided for @promptTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair with {device}?'**
  String promptTitle(String device);

  /// No description provided for @promptBody.
  ///
  /// In en, this message translates to:
  /// **'Only accept if {device} shows this code too.'**
  String promptBody(String device);

  /// No description provided for @promptAccept.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get promptAccept;

  /// No description provided for @promptReject.
  ///
  /// In en, this message translates to:
  /// **'Don\'t pair'**
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
  /// **'Pair a Device…'**
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
  /// **'Connection Doctor'**
  String get doctorTitle;

  /// No description provided for @doctorIntro.
  ///
  /// In en, this message translates to:
  /// **'Checking why {device} isn\'t connected.'**
  String doctorIntro(String device);

  /// No description provided for @doctorNetworkOk.
  ///
  /// In en, this message translates to:
  /// **'This device is on a network'**
  String get doctorNetworkOk;

  /// No description provided for @doctorNetworkProblem.
  ///
  /// In en, this message translates to:
  /// **'This device isn\'t on a network. Connect to Wi-Fi or Ethernet.'**
  String get doctorNetworkProblem;

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
  /// **'Both devices were on the same network'**
  String get doctorSameNetworkOk;

  /// No description provided for @doctorSameNetworkWarning.
  ///
  /// In en, this message translates to:
  /// **'{device} was last seen on a different network ({address}). Put both devices on the same Wi-Fi.'**
  String doctorSameNetworkWarning(String device, String address);

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
  /// **'{device} answered but didn\'t accept this device. It may have been reset or reinstalled. Pair again.'**
  String doctorAcceptedProblem(String device);

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
  /// **'Type the address shown in Settings on the other device.'**
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
  /// **'No devices connected'**
  String get dropNobody;

  /// No description provided for @dropNobodyDetail.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret on your phone first.'**
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
  /// **'Nothing took these files. Try again in a moment.'**
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
  /// **'That\'s not a Ferret code. Open Ferret on your computer and choose Pair a device.'**
  String get scanNotFerret;

  /// No description provided for @offersTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on more'**
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
  /// **'Install Ferret on your phone, open it, and tap Scan the code on your computer.'**
  String get onboardPairBodyComputer;

  /// No description provided for @onboardPairBodyPhone.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret on your computer, click Pair a device, then scan the code it shows.'**
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
  /// **'Type this on another device under Connect by address if it can\'t find this one.'**
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
  /// **'Forget this device'**
  String get deviceForget;

  /// No description provided for @deviceForgetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Forget {device}?'**
  String deviceForgetConfirmTitle(String device);

  /// No description provided for @deviceForgetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Both devices forget each other. You can pair them again any time.'**
  String get deviceForgetConfirmBody;

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
  /// **'Try this:\n1. Open Ferret on {device}.\n2. Put both devices on the same Wi-Fi.\n3. Guest and office Wi-Fi often keep devices apart. Try your home Wi-Fi or a phone hotspot.'**
  String doctorNotAnsweringSteps(String device);

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
