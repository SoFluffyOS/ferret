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
  String get homePairDevice => 'Pair a device';

  @override
  String get deviceConnected => 'Connected';

  @override
  String get deviceOffline => 'Not connected';

  @override
  String deviceLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get nearbyPairHint => 'Tap to pair';

  @override
  String get pairTitle => 'Pair a device';

  @override
  String get pairShowCode => 'Show code';

  @override
  String get pairEnterCode => 'Use a link';

  @override
  String get pairShowCodeBody =>
      'On your phone, open Ferret and tap Scan the code on your computer.';

  @override
  String get pairCopyLink => 'Copy link';

  @override
  String get pairLinkCopied => 'Link copied';

  @override
  String pairExpiresIn(int minutes) {
    return 'Expires in $minutes min';
  }

  @override
  String get pairNewCode => 'New code';

  @override
  String get pairLinkLabel => 'Pairing link';

  @override
  String get pairLinkHint => 'Paste a ferret://pair link';

  @override
  String get pairLinkInvalid => 'That isn\'t a Ferret pairing link.';

  @override
  String get pairAddressLabel => 'Address of the other device';

  @override
  String get pairAddressHint => 'e.g. 192.168.1.20:47640';

  @override
  String get pairConnect => 'Connect';

  @override
  String get pairCompareTitle => 'Compare the codes';

  @override
  String pairCompareBody(String device) {
    return 'Make sure $device shows the same code, then confirm there.';
  }

  @override
  String get pairWaiting => 'Waiting for the other device…';

  @override
  String pairSuccess(String device) {
    return 'Paired with $device';
  }

  @override
  String get pairFailedUnreachable =>
      'Couldn\'t reach that device. Are both on the same network?';

  @override
  String get pairFailedRejected => 'The other device said no.';

  @override
  String get pairFailedExpired => 'That code has expired. Show a new one.';

  @override
  String get pairFailedBadProof => 'That code doesn\'t match. Try a new one.';

  @override
  String get pairFailedWrongDevice =>
      'A different device answered. Pairing stopped to keep you safe.';

  @override
  String get pairFailedTimedOut => 'No answer in time.';

  @override
  String get pairFailedProtocol => 'Something went wrong while pairing.';

  @override
  String promptTitle(String device) {
    return 'Pair with $device?';
  }

  @override
  String promptBody(String device) {
    return 'Only accept if $device shows this code too.';
  }

  @override
  String get promptAccept => 'Pair';

  @override
  String get promptReject => 'Don\'t pair';

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
  String get menuPair => 'Pair a Device…';

  @override
  String get menuSettings => 'Settings…';

  @override
  String get menuQuit => 'Quit Ferret';

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
  String get pauseOneHour => 'Pause for 1 hour';

  @override
  String get pauseUntilTomorrow => 'Pause until tomorrow';

  @override
  String get pauseUntilResume => 'Pause until I resume';

  @override
  String get doctorTitle => 'Connection Doctor';

  @override
  String doctorIntro(String device) {
    return 'Checking why $device isn\'t connected.';
  }

  @override
  String get doctorNetworkOk => 'This device is on a network';

  @override
  String get doctorNetworkProblem =>
      'This device isn\'t on a network. Connect to Wi-Fi or Ethernet.';

  @override
  String doctorVpn(String name) {
    return 'A VPN is on ($name). It can hide devices on your network. Allow local network access in the VPN, or turn it off.';
  }

  @override
  String doctorPort(String port) {
    return 'Ferret is using port $port because the usual port was taken. That\'s fine.';
  }

  @override
  String get doctorSameNetworkOk => 'Both devices were on the same network';

  @override
  String doctorSameNetworkWarning(String device, String address) {
    return '$device was last seen on a different network ($address). Put both devices on the same Wi-Fi.';
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
  String doctorAcceptedProblem(String device) {
    return '$device answered but didn\'t accept this device. It may have been reset or reinstalled. Pair again.';
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
      'Type the address shown in Settings on the other device.';

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
  String get dropNobody => 'No devices connected';

  @override
  String get dropNobodyDetail => 'Open Ferret on your phone first.';

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
      'Nothing took these files. Try again in a moment.';

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
  String get scanTitle => 'Scan the code';

  @override
  String get scanBody =>
      'Point your camera at the code Ferret shows on your computer.';

  @override
  String get scanButton => 'Scan the code on your computer';

  @override
  String get scanSection => 'Scan';

  @override
  String get scanNotFerret =>
      'That\'s not a Ferret code. Open Ferret on your computer and choose Pair a device.';

  @override
  String get offersTitle => 'Turn on more';

  @override
  String get offersSubtitle => 'Each one asks only for what it needs.';

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
      'Install Ferret on your phone, open it, and tap Scan the code on your computer.';

  @override
  String get onboardPairBodyPhone =>
      'Open Ferret on your computer, click Pair a device, then scan the code it shows.';

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
      'Type this on another device under Connect by address if it can\'t find this one.';

  @override
  String get deviceWhyLong => 'Why isn\'t it connecting?';

  @override
  String deviceWhatWorks(String device) {
    return 'What works with $device';
  }

  @override
  String get deviceDetails => 'Details';

  @override
  String get deviceForget => 'Forget this device';

  @override
  String deviceForgetConfirmTitle(String device) {
    return 'Forget $device?';
  }

  @override
  String get deviceForgetConfirmBody =>
      'Both devices forget each other. You can pair them again any time.';

  @override
  String get chipOff => 'Off';

  @override
  String get doctorTryAgainPrimary => 'Try again';

  @override
  String doctorNotAnsweringSteps(String device) {
    return 'Try this:\n1. Open Ferret on $device.\n2. Put both devices on the same Wi-Fi.\n3. Guest and office Wi-Fi often keep devices apart. Try your home Wi-Fi or a phone hotspot.';
  }

  @override
  String get pauseTitle => 'Pause Ferret?';

  @override
  String get pauseBody =>
      'Your devices won\'t connect or sync until you resume.';

  @override
  String get settingsConnectByHand => 'Connect by hand';
}
