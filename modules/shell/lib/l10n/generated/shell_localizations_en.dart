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
      'Scan this code with Ferret on your other device, or open the link there.';

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
  String get pairLinkHint => 'ferret://pair?o=…';

  @override
  String get pairLinkInvalid => 'That isn\'t a Ferret pairing link.';

  @override
  String get pairAddressLabel => 'Or connect to an address';

  @override
  String get pairAddressHint => '192.168.1.20:47640';

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
    return '$device isn\'t answering. Open Ferret on it. On Android, battery saving may have stopped it. Some networks (guest or office Wi-Fi) block devices from seeing each other.';
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
  String get dropHere => 'Drop to send';

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
}
