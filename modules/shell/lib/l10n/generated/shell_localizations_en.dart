// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'shell_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ShellLocalizationsEn extends ShellLocalizations {
  ShellLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Ferret';

  @override
  String get homeYourDevices => 'Your devices';

  @override
  String get homeNearby => 'Nearby';

  @override
  String get homeNoDevicesTitle => 'No devices yet';

  @override
  String get homeNoDevicesBody =>
      'Pair your phone and your computer to start passing things between them.';

  @override
  String get homePairDevice => 'Add a device';

  @override
  String get deviceConnected => 'Connected';

  @override
  String get deviceOffline => 'Not connected';

  @override
  String get deviceNeedsAttention => 'Connected, needs attention';

  @override
  String get spokenOk => 'OK';

  @override
  String get spokenOff => 'Off';

  @override
  String get spokenWarning => 'Needs attention';

  @override
  String get spokenProblem => 'Problem';

  @override
  String get spokenChecking => 'Checking';

  @override
  String get deviceConnectsWhenOpen => 'Connects when Ferret is open on it';

  @override
  String deviceLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get nearbyPairHint => 'Tap to pair';

  @override
  String get pairTitle => 'Add a device';

  @override
  String get pairShowCode => 'Pair with a QR code';

  @override
  String get pairEnterCode => 'Other ways';

  @override
  String get pairIphoneBody =>
      'An iPhone can\'t look for devices on the network by itself. On your computer, open Ferret and click +. Then scan the code it shows.';

  @override
  String get pairShowCodeBody =>
      'On your phone, open Ferret and tap +, then Pair with a QR code.';

  @override
  String get pairCopyLink => 'Copy link';

  @override
  String get pairLinkCopied => 'Copied';

  @override
  String pairExpiresIn(int minutes) {
    return 'Expires in $minutes min';
  }

  @override
  String get pairNewCode => 'New code';

  @override
  String get pairLinkLabel => 'Paste a link';

  @override
  String get pairLinkHint => 'Paste a ferret://pair link';

  @override
  String get pairLinkInvalid => 'That isn\'t a Ferret pairing link.';

  @override
  String get pairAddressLabel => 'Address of the other device';

  @override
  String get pairAddressHint => 'e.g. 192.168.1.20:47640';

  @override
  String get pairConnect => 'Pair';

  @override
  String get pairCompareTitle =>
      'Check that your other device shows this code, then tap Pair there.';

  @override
  String pairCompareBody(String device) {
    return 'Make sure $device shows the same code, then confirm there.';
  }

  @override
  String get pairWaiting => 'Waiting for your other device…';

  @override
  String pairSuccess(String device) {
    return 'Paired with $device';
  }

  @override
  String get pairFailedUnreachable =>
      'Couldn\'t reach that device. Put both on the same Wi-Fi, then try again.';

  @override
  String get pairFailedUnreachableIphone =>
      'Couldn\'t reach that computer. Check that both are on the same Wi-Fi, and that Ferret may use the local network in Settings.';

  @override
  String get pairFailedRejected => 'Your other device said not now.';

  @override
  String get pairFailedExpired => 'That code expired.';

  @override
  String get pairFailedBadProof =>
      'The codes didn\'t match, so nothing was paired. Try once more, close to the other device.';

  @override
  String get pairFailedWrongDevice =>
      'A different device answered. Pairing stopped to keep you safe.';

  @override
  String get pairFailedTimedOut => 'Your other device didn\'t answer.';

  @override
  String get pairFailedProtocol =>
      'Pairing stopped before it finished. Try again.';

  @override
  String pairCodeSpoken(String digits) {
    return 'Code: $digits';
  }

  @override
  String promptTitle(String device) {
    return 'Pair with $device?';
  }

  @override
  String promptBody(String device) {
    return 'Pair only if $device shows the same code.';
  }

  @override
  String get promptAccept => 'Pair';

  @override
  String get promptReject => 'Not now';

  @override
  String get deviceTitleId => 'Device ID';

  @override
  String get deviceActions => 'Actions';

  @override
  String get deviceUnpair => 'Unpair';

  @override
  String deviceUnpairConfirmTitle(String device) {
    return 'Unpair $device?';
  }

  @override
  String get deviceUnpairConfirmBody =>
      'Both devices forget each other. You can pair again any time.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsThisDevice => 'This device';

  @override
  String settingsDeviceId(String id) {
    return 'ID $id';
  }

  @override
  String settingsPort(int port) {
    return 'Listening on port $port';
  }

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyBody =>
      'Ferret talks only to devices you paired, directly on your network, end-to-end encrypted. No account, no cloud, no telemetry.';

  @override
  String get settingsQuit => 'Quit Ferret';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get menuOpen => 'Open Ferret';

  @override
  String get menuOpenWindow => 'Open Ferret Window';

  @override
  String get homeOpenWindow => 'Open Ferret window';

  @override
  String get settingsDock => 'Dock';

  @override
  String get settingsAlwaysInDock => 'Always show in the Dock';

  @override
  String get settingsAlwaysInDockBody =>
      'When off, Ferret is in the Dock only while its window is open.';

  @override
  String get menuPair => 'Add a Device…';

  @override
  String get menuSettings => 'Settings…';

  @override
  String get menuQuit => 'Quit Ferret';

  @override
  String menubarTipConnectedTo(String device) {
    return 'Ferret · Connected to $device';
  }

  @override
  String menubarTipConnected(int count) {
    return 'Ferret · $count devices connected';
  }

  @override
  String get menubarTipAlone => 'Ferret · No device connected';

  @override
  String menubarTipSendingTo(String device) {
    return 'Ferret · Sending to $device';
  }

  @override
  String menubarTipReceivingFrom(String device) {
    return 'Ferret · Receiving from $device';
  }

  @override
  String get menubarTipSending => 'Ferret · Sending';

  @override
  String get menubarTipReceiving => 'Ferret · Receiving';

  @override
  String get menubarTipDone => 'Ferret · Done';

  @override
  String menubarTipPair(String device) {
    return 'Ferret · $device wants to pair';
  }

  @override
  String menubarTipRequest(String device) {
    return 'Ferret · $device wants to send you something';
  }

  @override
  String menubarTipWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests are waiting for you',
      one: '1 request is waiting for you',
    );
    return 'Ferret · $_temp0';
  }

  @override
  String get menubarTipPaused => 'Ferret · Paused';

  @override
  String get welcomeTitle => 'Your devices, working together';

  @override
  String get welcomeBody =>
      'Pair your phone and computer to pass pages, media, files and your clipboard between them.';

  @override
  String get welcomePrivacy => 'No account. No cloud. Stays on your network.';

  @override
  String get welcomePlatforms => 'Android · iPhone · Mac · Windows · Linux';

  @override
  String get deviceLastSeenJustNow => 'Last seen just now';

  @override
  String deviceLastSeenMinutes(int minutes) {
    return 'Last seen $minutes min ago';
  }

  @override
  String deviceLastSeenHours(int hours) {
    return 'Last seen $hours h ago';
  }

  @override
  String deviceLastSeenDays(int days) {
    return 'Last seen $days d ago';
  }

  @override
  String get deviceWhy => 'Why?';

  @override
  String get pausedTitle => 'Ferret is paused';

  @override
  String pausedUntil(String time) {
    return 'Until $time';
  }

  @override
  String get pausedUntilResume => 'Until you resume';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get pauseOneHour => 'Pause syncing for 1 hour';

  @override
  String get pauseUntilTomorrow => 'Pause syncing until tomorrow';

  @override
  String get pauseUntilResume => 'Pause syncing until I resume';

  @override
  String get doctorTitle => 'Fix connection';

  @override
  String doctorIntro(String device) {
    return 'Checking why $device isn\'t connected.';
  }

  @override
  String doctorNetworkOk(String here) {
    return '$here is on a network';
  }

  @override
  String doctorNetworkProblem(String here) {
    return '$here isn\'t on a network. Connect to Wi-Fi or Ethernet.';
  }

  @override
  String doctorVpn(String name) {
    return 'A VPN is on ($name). It can hide devices on your network. Allow local network access in the VPN, or turn it off.';
  }

  @override
  String doctorPort(String port) {
    return 'Ferret is using port $port because the usual port was taken. That\'s fine.';
  }

  @override
  String doctorSameNetworkOk(String device, String here) {
    return '$device and $here were on the same network';
  }

  @override
  String doctorSameNetworkWarning(String device, String address, String here) {
    return '$device was last seen on a different network ($address). Put $device and $here on the same Wi-Fi.';
  }

  @override
  String doctorReachableRunning(String device) {
    return 'Knocking on $device…';
  }

  @override
  String doctorReachableOk(String device) {
    return '$device answered';
  }

  @override
  String doctorReachableProblem(String device) {
    return '$device isn\'t answering.';
  }

  @override
  String get doctorAcceptedRunning => 'Connecting…';

  @override
  String get doctorAcceptedOk => 'Connected. All good.';

  @override
  String doctorAcceptedProblem(String device, String here) {
    return '$device answered but doesn\'t know $here any more. It may have been reset or reinstalled. Pair them again.';
  }

  @override
  String get doctorFixTryAgain => 'Try again';

  @override
  String get doctorFixConnectByAddress => 'Connect by address';

  @override
  String get doctorFixPairAgain => 'Pair again';

  @override
  String get doctorFixCopy => 'Copy diagnostics';

  @override
  String get doctorCopied =>
      'Diagnostics copied. They contain no names or content.';

  @override
  String get connectTitle => 'Connect by address';

  @override
  String get connectBody =>
      'On the other device, open Ferret, then Settings and Advanced. Type the address it shows.';

  @override
  String get featureChipOff => 'Off';

  @override
  String get settingsPause => 'Pause';

  @override
  String get stayTitle => 'Stay connected';

  @override
  String get stayBody =>
      'Android stops apps in the background to save battery. These steps keep Ferret connected. It uses about 1% battery a day.';

  @override
  String get stayNotifications =>
      'Allow Ferret\'s notification, so Android lets it keep running.';

  @override
  String get stayNotificationsFix => 'Allow';

  @override
  String get stayBattery => 'Let Ferret run in the background.';

  @override
  String get stayBatteryFix => 'Allow';

  @override
  String stayMaker(String maker) {
    return 'Your $maker phone has its own battery saver too. Allow Ferret there.';
  }

  @override
  String get stayMakerFix => 'Open settings';

  @override
  String stayStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return 'Android stopped Ferret $_temp0 today.';
  }

  @override
  String get stayTile =>
      'Add the Ferret tile to Quick Settings to send your clipboard in one tap.';

  @override
  String get stayTileFix => 'Add tile';

  @override
  String get settingsBackground => 'Background';

  @override
  String get settingsKeepRunning => 'Keep running in the background';

  @override
  String get settingsKeepRunningBody =>
      'Stays connected when Ferret is closed. Shows a quiet notification.';

  @override
  String get settingsStartOnBoot => 'Start when the phone starts';

  @override
  String dropTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Send $count files to…',
      one: 'Send a file to…',
      zero: 'Send files to…',
    );
    return '$_temp0';
  }

  @override
  String get dropTileDrop => 'Drop to send';

  @override
  String get dropTilePick => 'Send here';

  @override
  String get dropTileOffline => 'Offline';

  @override
  String get dropAllDevices => 'All my devices';

  @override
  String get dropNobody => 'No device to send to';

  @override
  String get dropNobodyDetail => 'Open Ferret on your other device first.';

  @override
  String dropSendingTo(String name) {
    return 'Sending to $name';
  }

  @override
  String dropSentTo(String name) {
    return 'Sent to $name';
  }

  @override
  String dropFailedTo(String name) {
    return 'Couldn\'t send to $name';
  }

  @override
  String get dropFailedDetail =>
      'The files weren\'t sent. Try again in a moment.';

  @override
  String get dropAllDevicesName => 'all my devices';

  @override
  String dropFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get dropTryAgain => 'Try again';

  @override
  String get dropClose => 'Close';

  @override
  String get dropCancel => 'Cancel';

  @override
  String dropSendTo(String name) {
    return 'Send to $name';
  }

  @override
  String dropSendToAll(int count) {
    return 'Send to all $count devices';
  }

  @override
  String dropDeviceOffline(String name) {
    return '$name is offline';
  }

  @override
  String get scanTitle => 'Scan the code';

  @override
  String get scanBody =>
      'On your computer, open Ferret and choose Pair with a QR code. Then point your camera at it.';

  @override
  String get scanButton => 'Scan the code on your computer';

  @override
  String get scanSection => 'Scan';

  @override
  String get scanNotFerret =>
      'That\'s not a Ferret code. On your computer, open Ferret and tap +, then Pair with a QR code.';

  @override
  String get offersTitle => 'Do more';

  @override
  String get offersSubtitle => 'Extras you can turn on. All optional.';

  @override
  String get onboardWelcomeTitle => 'Your devices, working together';

  @override
  String get onboardWelcomeBody =>
      'Ferret passes what you\'re doing between your phone and your computer.';

  @override
  String get onboardPointContinue =>
      'Continue a page or song on another device';

  @override
  String get onboardPointClipboard => 'Copy on one, paste on the other';

  @override
  String get onboardPointFiles => 'Send files and photos in a second';

  @override
  String get onboardPointPhone =>
      'See your phone\'s calls, texts and notifications';

  @override
  String get onboardStart => 'Get started';

  @override
  String onboardStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get onboardNameTitle => 'Name this device';

  @override
  String get onboardNameBody => 'Your other devices will show it by this name.';

  @override
  String get onboardNameLabel => 'Device name';

  @override
  String get onboardContinue => 'Continue';

  @override
  String get onboardPairTitle => 'Pair your other device';

  @override
  String get onboardPairBodyComputer =>
      'Open Ferret on your phone, on the same Wi-Fi. It shows up here.';

  @override
  String get onboardPairBodyPhone =>
      'Open Ferret on your computer, on the same Wi-Fi. It shows up here.';

  @override
  String get onboardPairWaiting => 'Waiting for your other device…';

  @override
  String onboardPairDone(String device) {
    return 'Paired with $device';
  }

  @override
  String get onboardShowMyCode => 'Show my code instead';

  @override
  String get onboardMoreWays => 'More ways to pair';

  @override
  String get onboardLater => 'Do this later';

  @override
  String get onboardReadyTitle => 'You\'re all set';

  @override
  String onboardReadyBodyPaired(String device) {
    return '$device and this device are connected.';
  }

  @override
  String get onboardReadyBodyLater =>
      'Pair a device any time with the + button.';

  @override
  String get onboardTipCopy =>
      'Copy something here, then paste it on your other device.';

  @override
  String get onboardTipDropComputer => 'Drop files on Ferret to send them.';

  @override
  String get onboardTipSharePhone =>
      'Use Share → Send with Ferret to send files and links.';

  @override
  String get onboardTipMenubar =>
      'Ferret lives in the menubar. Click ⇆ at the top of the screen.';

  @override
  String get onboardTipTray => 'Ferret lives in the tray, next to the clock.';

  @override
  String get onboardTipAndroid =>
      'Ferret keeps a quiet notification so it stays connected.';

  @override
  String get onboardTipMore =>
      'Turn on more (calls, texts, notifications) from the home screen.';

  @override
  String get onboardFinish => 'Start using Ferret';

  @override
  String get settingsRename => 'Rename';

  @override
  String get settingsRenameTitle => 'Name this device';

  @override
  String settingsAddress(String address) {
    return 'Address: $address';
  }

  @override
  String get settingsAddressHint =>
      'If another device can\'t find this one: on it, open Add a device, then Other ways, and type this address.';

  @override
  String get deviceWhyLong => 'Why isn\'t it connecting?';

  @override
  String deviceWhatWorks(String device) {
    return 'What works with $device';
  }

  @override
  String get deviceDetails => 'Details';

  @override
  String deviceForget(String device) {
    return 'Forget $device';
  }

  @override
  String deviceForgetConfirmTitle(String device) {
    return 'Forget $device?';
  }

  @override
  String deviceForgetConfirmBody(String device, String here) {
    return '$device and $here forget each other. You can pair them again any time.';
  }

  @override
  String get chipOff => 'Off';

  @override
  String get doctorTryAgainPrimary => 'Try again';

  @override
  String doctorNotAnsweringSteps(String device, String here) {
    return 'Try this:\n1. On $device, open Ferret.\n2. Put $device and $here on the same Wi-Fi.\n3. Guest and office Wi-Fi often keep devices apart. Try your home Wi-Fi or a phone hotspot.';
  }

  @override
  String get pauseTitle => 'Pause Ferret?';

  @override
  String get pauseBody =>
      'Your devices won\'t connect or sync until you resume.';

  @override
  String get settingsConnectByHand => 'Connect by hand';

  @override
  String get nearbyLooking => 'Looking…';

  @override
  String get nearbyNone => 'No devices found yet.';

  @override
  String get nearbyLookAgain => 'Look again';

  @override
  String get nearbyPair => 'Pair';

  @override
  String nearbyConnecting(String device) {
    return 'Connecting to $device…';
  }

  @override
  String nearbyCheckCode(String device) {
    return 'Check that $device shows this code.';
  }

  @override
  String get nearbyTheyMatch => 'They match';

  @override
  String nearbyTapThere(String device) {
    return 'On $device, tap Pair.';
  }

  @override
  String nearbyWaiting(String device) {
    return 'Waiting for $device…';
  }

  @override
  String get nearbyTryAgain => 'Try again';

  @override
  String nearbyNoAnswer(String device) {
    return '$device didn\'t answer.';
  }

  @override
  String nearbyNotNow(String device) {
    return '$device said not now.';
  }

  @override
  String nearbyUnreachable(String device) {
    return 'Couldn\'t reach $device. Are both on the same Wi-Fi?';
  }

  @override
  String get nearbyBlockedTitle => 'Ferret can\'t look for your devices';

  @override
  String get nearbyBlockedBody =>
      'Your system needs your OK. Allow Ferret under Privacy & Security, Local Network.';

  @override
  String get nearbyOpenSettings => 'Open Settings';

  @override
  String get pairCantSee => 'Can\'t see your device?';

  @override
  String get pairCantSeeSteps =>
      '1. Open Ferret on the other device.\n2. Put both on the same Wi-Fi.\n3. Still nothing? Check my network tells you why.';

  @override
  String promptAlsoOne(String first) {
    return 'You\'ll also be connected to $first.';
  }

  @override
  String promptAlsoTwo(String first, String second) {
    return 'You\'ll also be connected to $first and $second.';
  }

  @override
  String promptAlsoMore(String first, String second, int count) {
    return 'You\'ll also be connected to $first, $second and $count more.';
  }

  @override
  String promptSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String promptNotice(String device) {
    return '$device wants to pair';
  }

  @override
  String get promptNoticeBody => 'Open Ferret to compare the code.';

  @override
  String joinedNotice(String device) {
    return '$device joined your devices';
  }

  @override
  String joinedNoticeBody(String introducer) {
    return 'Added by $introducer';
  }

  @override
  String joinedBanner(String device, String introducer) {
    return '$device joined your devices (added by $introducer)';
  }

  @override
  String get joinedUndo => 'Undo';

  @override
  String get joinedKeep => 'Keep';

  @override
  String devicePairedThrough(String device) {
    return 'Paired through $device';
  }

  @override
  String deviceForgetScopeBody(String device) {
    return '$device is connected to your other devices too.';
  }

  @override
  String get deviceForgetEverywhere => 'Remove from all my devices';

  @override
  String deviceForgetHere(String here) {
    return 'Forget on $here only';
  }

  @override
  String get settingsSharePairings => 'Pair once for all my devices';

  @override
  String get settingsSharePairingsBody =>
      'A device you pair here joins all your devices. Remove it once and it leaves them all.';

  @override
  String doctorNothingWrong(String here, String device) {
    return 'Everything looks right on $here. On $device, open Ferret.';
  }

  @override
  String doctorNetworkIntro(String here) {
    return 'Checking the network on $here.';
  }

  @override
  String doctorNetworkAllGood(String here) {
    return 'Everything looks right on $here. Open Ferret on your other device, on the same Wi-Fi.';
  }

  @override
  String get connectAction => 'Try this address';

  @override
  String get thisMac => 'this Mac';

  @override
  String get thisPhone => 'this phone';

  @override
  String get thisTablet => 'this tablet';

  @override
  String get thisComputer => 'this computer';

  @override
  String get thisMacStart => 'This Mac';

  @override
  String get thisPhoneStart => 'This phone';

  @override
  String get thisTabletStart => 'This tablet';

  @override
  String get thisComputerStart => 'This computer';

  @override
  String get settingsGroupClipboard => 'Clipboard';

  @override
  String get settingsGroupFiles => 'Files';

  @override
  String get settingsGroupContinue => 'Continue & media';

  @override
  String get settingsGroupFromPhone => 'From your phone';

  @override
  String get settingsGroupToComputer => 'To your computer';

  @override
  String get settingsGroupControl => 'Control';

  @override
  String get settingsGroupOtherApps => 'Other apps';

  @override
  String get settingsOn => 'On';

  @override
  String get settingsOff => 'Off';

  @override
  String settingsCountOn(int on, int total) {
    return '$on of $total on';
  }

  @override
  String settingsNamedOn(String names) {
    return '$names on';
  }

  @override
  String get settingsNeedsAttention => 'Needs attention';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsAbout => 'About · Privacy';

  @override
  String settingsVersion(String version) {
    return 'Ferret $version';
  }

  @override
  String get settingsLicense =>
      'Free software under GPL-3.0. The protocol is open too, under MIT.';

  @override
  String get settingsDeviceIdLabel => 'Device ID';

  @override
  String get settingsAddressLabel => 'Address';

  @override
  String get settingsCopy => 'Copy';

  @override
  String get settingsCheckNetwork => 'Check my network';

  @override
  String get settingsNothingHere =>
      'Nothing to set here yet. Pair a device first.';

  @override
  String deviceMay(String device) {
    return '$device may';
  }

  @override
  String get deviceHow => 'How?';

  @override
  String get deviceFix => 'Fix';

  @override
  String devicePairedOn(String date) {
    return 'Paired on $date';
  }

  @override
  String deviceNothingWorks(String device) {
    return 'Nothing to show yet. Keep Ferret open on $device.';
  }

  @override
  String get addDontSee => 'Don\'t see it?';

  @override
  String addShowsAs(String name) {
    return 'Shows as $name';
  }

  @override
  String get qrScanEnough => 'Scanning is enough. No code to compare.';

  @override
  String get qrWaiting => 'Waiting for your phone…';

  @override
  String get qrScanRow => 'Scan a QR code';

  @override
  String get otherShowQr => 'Show a QR code';

  @override
  String get otherLinkTitle => 'With a link';

  @override
  String get otherLinkBody =>
      'Copy this device\'s link and open it on the other one, or paste the other one\'s link here.';

  @override
  String get otherAddressTitle => 'With an address';

  @override
  String get otherAddressBody =>
      'For networks that hide devices from each other. The address is in Ferret\'s Settings, under Advanced, on the other device.';

  @override
  String get otherPairLink => 'Pair with link';

  @override
  String get otherPairAddress => 'Pair with address';

  @override
  String get homeMore => 'More';

  @override
  String get homeStatusPaused => 'Paused';

  @override
  String deviceAttention(String feature) {
    return 'Connected · $feature: needs attention';
  }

  @override
  String devicesOffline(int count) {
    return '$count offline';
  }

  @override
  String get devicesShow => 'Show';

  @override
  String get emptyBody =>
      'Install Ferret on your other device too, and open it. It shows up here when both are on the same Wi-Fi. An iPhone pairs with a QR code instead.';

  @override
  String get emptyBodyIphone =>
      'Install Ferret on your computer too, and open it. Then scan the code it shows.';

  @override
  String get emptyCantSee => 'Can\'t see it?';

  @override
  String get emptyGetFerretPhone => 'Get Ferret for your phone';

  @override
  String get emptyGetFerretComputer => 'Get Ferret for your computer';

  @override
  String get welcomeNearbyBody =>
      'Tap Pair next to your other device. You only do it once.';

  @override
  String get nearbyNotTheOne =>
      'Not the one you want? Open Ferret on your other device.';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activitySeeAll => 'See all';

  @override
  String get activityDismiss => 'Dismiss';

  @override
  String get needsYouTitle => 'Needs you';

  @override
  String get activityEmpty => 'Nothing yet. Copy something or send a file.';

  @override
  String get activityNow => 'now';

  @override
  String activityMinutes(int count) {
    return '$count min';
  }

  @override
  String activityHours(int count) {
    return '$count h';
  }

  @override
  String activityDays(int count) {
    return '$count d';
  }

  @override
  String get footerDrag => 'Drag files onto a device to send';

  @override
  String get footerKeepOpen =>
      'Keep Ferret open to sync. iOS pauses it otherwise.';

  @override
  String get footerNobody =>
      'Your devices are offline. Open Ferret on one to reach it.';

  @override
  String footerPausedUntil(String time) {
    return 'Paused until $time';
  }

  @override
  String get footerPaused => 'Paused until you resume';

  @override
  String tipCopyHere(String device) {
    return 'Try it: copy something here, then paste on $device.';
  }

  @override
  String tipCopyThere(String device) {
    return 'Try it: copy something on $device, then paste here.';
  }

  @override
  String get tipDone => 'That\'s it.';

  @override
  String get tipDrag =>
      'Drag files onto the Ferret icon in the menubar to send them.';

  @override
  String get tipDismiss => 'Got it';

  @override
  String get doctorFirewall =>
      'Windows Firewall may be blocking Ferret.\n1. Tap Open Windows Firewall, then Change settings.\n2. Tick Ferret, under both Private and Public.\n3. Select OK, then Try again.';

  @override
  String get doctorFixOpenFirewall => 'Open Windows Firewall';

  @override
  String get sidebarHide => 'Hide sidebar';

  @override
  String get sidebarShow => 'Show sidebar';

  @override
  String get sectionOverview => 'Overview';

  @override
  String windowTitleSection(String device, String section) {
    return '$device — $section';
  }

  @override
  String get menuFile => 'File';

  @override
  String get menuView => 'View';

  @override
  String get menuDevice => 'Device';

  @override
  String get menuWindow => 'Window';

  @override
  String get menuSendFiles => 'Send Files…';

  @override
  String get menuSendClipboard => 'Send Clipboard';

  @override
  String get menuCloseWindow => 'Close Window';

  @override
  String get menuShowSidebar => 'Show Sidebar';

  @override
  String get menuHideSidebar => 'Hide Sidebar';

  @override
  String get menuBack => 'Back';

  @override
  String get menuNextDevice => 'Next Device';

  @override
  String get menuPreviousDevice => 'Previous Device';

  @override
  String get menuFixConnection => 'Fix Connection…';

  @override
  String get activityPaneNow => 'Now';

  @override
  String activityPaneRecent(String device) {
    return 'Recent with $device';
  }

  @override
  String activityPaneEmpty(String device) {
    return 'Things you send and receive with $device show here.';
  }

  @override
  String get menuShowActivityPane => 'Show Activity Pane';

  @override
  String get menuHideActivityPane => 'Hide Activity Pane';

  @override
  String get menuForgetDevice => 'Forget This Device…';

  @override
  String get activityOpen => 'Open';

  @override
  String sectionOffline(String device, String time) {
    return '$device is offline. Last updated $time.';
  }

  @override
  String sectionOfflineNoTime(String device) {
    return '$device is offline. This is what was here last.';
  }

  @override
  String doctorFirewallLinux(String firewall) {
    return '$firewall is on, and it blocks Ferret until you let it through.\n1. Tap Copy the command.\n2. Paste it in a terminal and enter your password.\n3. Try again.';
  }

  @override
  String get doctorFixCopyFirewallCommand => 'Copy the command';
}
