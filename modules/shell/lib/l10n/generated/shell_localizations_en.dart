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
}
