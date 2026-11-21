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
  String get homePairDevice => 'Add a device';

  @override
  String get deviceConnected => 'Connected';

  @override
  String get deviceOffline => 'Not connected';

  @override
  String get deviceReconnecting => 'Reconnecting…';

  @override
  String get deviceWeak => 'Connected · weak connection';

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
  String get pairTitle => 'Add a device';

  @override
  String get pairShowCode => 'Pair with a QR code';

  @override
  String get pairEnterCode => 'Other ways';

  @override
  String get pairIphoneBody =>
      'An iPhone can\'t look for devices on the network by itself. On your computer, open Ferret, click +, then Pair with a QR code. Scan it here, or with the iPhone\'s Camera.';

  @override
  String get pairShowCodeBody =>
      'On your phone, open Ferret and tap +, then Pair with a QR code.';

  @override
  String get pairCopyLink => 'Copy link';

  @override
  String get pairLinkCopied => 'Copied';

  @override
  String pairExpiresIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
    );
    return 'Expires in $_temp0';
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
  String get pairCompareTitle =>
      'Check that your other device shows this code, then tap Pair there.';

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
  String get pairFailedExpired =>
      'That code expired. Tap New code on your computer, then scan again.';

  @override
  String get pairFailedBadProof =>
      'The codes didn\'t match, so nothing was paired. Try once more, close to the other device.';

  @override
  String get pairFailedWrongDevice =>
      'A different device answered. Pairing stopped to keep you safe.';

  @override
  String get pairFailedTimedOut => 'Your other device didn\'t answer.';

  @override
  String pairFailedUpdateHere(String name) {
    return '$name has a newer Ferret. Update Ferret here, then scan again.';
  }

  @override
  String pairFailedUpdateThere(String name) {
    return '$name needs a newer Ferret. Update it there, then show the code again.';
  }

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
  String deviceIdLine(String id) {
    return 'Device ID $id';
  }

  @override
  String get deviceActions => 'Actions';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsThisDevice => 'This device';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices connected',
      one: '1 device connected',
    );
    return 'Ferret · $_temp0';
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
  String get welcomePrivacy => 'No account. No cloud. Stays on your network.';

  @override
  String get welcomePlatforms => 'Android · iPhone · Mac · Windows · Linux';

  @override
  String get deviceLastSeenJustNow => 'Last seen just now';

  @override
  String deviceLastSeenMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
    );
    return 'Last seen $_temp0 ago';
  }

  @override
  String deviceLastSeenHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours h',
    );
    return 'Last seen $_temp0 ago';
  }

  @override
  String deviceLastSeenDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days d',
    );
    return 'Last seen $_temp0 ago';
  }

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
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'This Mac',
        'phone': 'This phone',
        'tablet': 'This tablet',
        'other': 'This computer',
      },
    );
    return '$_temp0 is on a network';
  }

  @override
  String doctorNetworkProblem(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'This Mac',
        'phone': 'This phone',
        'tablet': 'This tablet',
        'other': 'This computer',
      },
    );
    return '$_temp0 isn\'t on a network. Connect to Wi-Fi or Ethernet.';
  }

  @override
  String doctorMobileDataAny(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'This Mac',
        'phone': 'This phone',
        'tablet': 'This tablet',
        'other': 'This computer',
      },
    );
    return '$_temp0 is on mobile data, and Ferret needs Wi-Fi to find your devices. Join the same Wi-Fi as them.';
  }

  @override
  String doctorMobileData(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'This Mac',
        'phone': 'This phone',
        'tablet': 'This tablet',
        'other': 'This computer',
      },
    );
    return '$_temp0 is on mobile data, and Ferret needs Wi-Fi to find $device. Join the same Wi-Fi, or reach $device over your own VPN.';
  }

  @override
  String doctorMobileDataVpn(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'This Mac',
        'phone': 'This phone',
        'tablet': 'This tablet',
        'other': 'This computer',
      },
    );
    return '$_temp0 is on mobile data. Ferret will try $device over your VPN.';
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
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '$device and $_temp0 were on the same network';
  }

  @override
  String doctorSameNetworkWarning(String device, String address, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '$device was last seen on a different network ($address). Put $device and $_temp0 on the same Wi-Fi.';
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
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '$device answered but doesn\'t know $_temp0 any more. It may have been reset or reinstalled. Pair them again.';
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
  String get connectTitle => 'Connect by address';

  @override
  String get connectBody =>
      'On the other device, open Ferret, then Settings and Advanced. Type the address it shows.';

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
  String get stayBattery =>
      'Android may stop Ferret in the background. Let it keep running.';

  @override
  String get stayBatteryFix => 'Fix';

  @override
  String get stayRestricted =>
      'Battery use for Ferret is set to Restricted, so Android stops Ferret each time you leave the app.';

  @override
  String get stayRestrictedSteps =>
      'Open App battery usage and choose Unrestricted.';

  @override
  String get stayRestrictedFix => 'Fix';

  @override
  String get stayStepsXiaomi =>
      'Settings → Apps → Manage apps → Ferret: turn on Autostart and set Battery saver to No restrictions.';

  @override
  String get stayStepsSamsung =>
      'Settings → Battery → Background usage limits → Never sleeping apps: add Ferret.';

  @override
  String get stayStepsOneplus =>
      'Settings → Apps → Ferret → Battery usage: turn on Allow background activity. Then lock Ferret in the recent apps view.';

  @override
  String get stayStepsHuawei =>
      'Settings → Battery → App launch → Ferret: turn off Manage automatically and keep all three switches on.';

  @override
  String get stayStepsOppo =>
      'Settings → Apps → Ferret → Battery usage: turn on Allow background activity and Allow auto launch.';

  @override
  String get stayStepsVivo =>
      'Settings → Battery → Background power consumption management → Ferret: allow it. Turn on Autostart for Ferret too.';

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
  String stayBootAsk(String device) {
    return 'Start Ferret when $device restarts? Otherwise it reconnects only when you open it.';
  }

  @override
  String get stayBootYes => 'Yes';

  @override
  String get stayBootNotNow => 'Not now';

  @override
  String get settingsBackground => 'Background';

  @override
  String get settingsKeepRunning => 'Keep running in the background';

  @override
  String get settingsKeepRunningBody =>
      'Stays connected when Ferret is closed. Shows a quiet notification.';

  @override
  String settingsStartOnBoot(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'tablet',
        'other': 'phone',
      },
    );
    return 'Start when the $_temp0 starts';
  }

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
  String dropFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count folders',
      one: '1 folder',
    );
    return '$_temp0';
  }

  @override
  String dropFilesAndFolders(String files, String folders) {
    return '$files and $folders';
  }

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
  String get dropTitleText => 'Send text to…';

  @override
  String get dropTitleLink => 'Open link on…';

  @override
  String get dropKindText => 'Text, to its clipboard';

  @override
  String get dropKindLink => 'Link, opens there';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
    );
    return 'Send to all $_temp0';
  }

  @override
  String dropToSendTo(String name) {
    return 'Drop to send to $name';
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
  String get scanButtonShort => 'Scan the code';

  @override
  String get scanNotFerret =>
      'That\'s not a Ferret code. On your computer, open Ferret and click +, then Pair with a QR code.';

  @override
  String get offersTitle => 'Do more';

  @override
  String get offersSubtitle => 'Extras you can turn on. All optional.';

  @override
  String get onboardNameLabel => 'Device name';

  @override
  String get settingsRename => 'Rename';

  @override
  String get settingsRenameTitle => 'Name this device';

  @override
  String thisDeviceShared(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Other accounts on $_temp0 use Ferret too. Each one has its own devices.';
  }

  @override
  String get thisDeviceOnlyMe => 'Only me';

  @override
  String thisDeviceOnlyMeHint(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Only I use $_temp0. Previews show again unless you turned them off for a device, and the name drops the account. If Ferret hears another account here, it counts as shared again.';
  }

  @override
  String thisDeviceOtherPort(String port, String usual) {
    return 'Listening on port $port: another account has $usual.';
  }

  @override
  String get privateCoverBody => 'Open Ferret to see it.';

  @override
  String privateCoverDetail(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Hidden on $_temp0';
  }

  @override
  String previewsTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Show previews on $_temp0';
  }

  @override
  String previewsBody(String device) {
    return 'Notifications, texts, callers and copied text from $device show on this screen. Off, Ferret only says that something arrived. They always hide while the screen is locked or another account is in front.';
  }

  @override
  String previewsSharedDefault(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Off at first here, because other accounts on $_temp0 use Ferret.';
  }

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
  String get deviceWhyShort => 'Find out why';

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
  String get deviceForgetShort => 'Forget';

  @override
  String deviceForgetConfirmTitle(String device) {
    return 'Forget $device?';
  }

  @override
  String deviceForgetConfirmBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '$device and $_temp0 forget each other. You can pair them again any time.';
  }

  @override
  String get doctorTryAgainPrimary => 'Try again';

  @override
  String doctorNotAnsweringSteps(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Try this:\n1. On $device, open Ferret.\n2. Put $device and $_temp0 on the same Wi-Fi.\n3. Guest and office Wi-Fi often keep devices apart. Try your home Wi-Fi or a phone hotspot.';
  }

  @override
  String get nearbyLooking => 'Looking…';

  @override
  String get nearbyNone => 'No devices found yet.';

  @override
  String get nearbyLookAgain => 'Look again';

  @override
  String get nearbyPair => 'Pair';

  @override
  String nearbyPairWith(String name) {
    return 'Pair with $name';
  }

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more',
    );
    return 'You\'ll also be connected to $first, $second and $_temp0.';
  }

  @override
  String promptSecondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds s',
    );
    return '$_temp0';
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
  String get deviceForgetEverywhereShort => 'Remove everywhere';

  @override
  String deviceForgetHere(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Forget on $_temp0 only';
  }

  @override
  String get deviceForgetHereShort => 'Forget here only';

  @override
  String get settingsSharePairings => 'Pair once for all my devices';

  @override
  String get settingsSharePairingsBody =>
      'A device you pair here joins all your devices. Remove it once and it leaves them all.';

  @override
  String doctorIsolated(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'This Mac',
        'phone': 'This phone',
        'tablet': 'This tablet',
        'other': 'This computer',
      },
    );
    return 'This network keeps devices apart. $_temp0 reaches the router but not $device. Café, hotel, campus and guest Wi-Fi often do this. Put both on your phone\'s hotspot or a home network.';
  }

  @override
  String get doctorIsolatedMaybe =>
      'Ferret hasn\'t heard any other device on this network. If the other device is on the same Wi-Fi, this network may keep devices apart, as café, hotel and guest Wi-Fi often do. Put both on your phone\'s hotspot or a home network.';

  @override
  String doctorNothingWrong(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Everything looks right on $_temp0. On $device, open Ferret.';
  }

  @override
  String doctorNetworkIntro(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Checking the network on $_temp0.';
  }

  @override
  String doctorNetworkAllGood(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Everything looks right on $_temp0. Open Ferret on your other device, on the same Wi-Fi.';
  }

  @override
  String get connectAction => 'Try this address';

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
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Same as the system';

  @override
  String settingsLanguageNote(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Menus, the menu bar icon and notifications switch the next time Ferret starts.',
        'other': 'Menus, the tray icon and notifications switch the next time Ferret starts.',
      },
    );
    return '$_temp0';
  }

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
  String get settingsSponsor => 'Sponsor Ferret';

  @override
  String get settingsSponsorDetail =>
      'Ferret is free. If it saves you time, you can sponsor its work on GitHub.';

  @override
  String get settingsDeviceIdLabel => 'Device ID';

  @override
  String get settingsAddressLabel => 'Address';

  @override
  String get settingsCheckNetwork => 'Check my network';

  @override
  String get settingsNothingHere =>
      'Nothing to set here yet. Pair a device first.';

  @override
  String get settingsShortcutTitle => 'Open Ferret from anywhere';

  @override
  String get settingsClipsShortcutTitle => 'Recent clips from anywhere';

  @override
  String get settingsClipsShortcutBody =>
      'Press these keys in any app to see the last things you copied, on any device.';

  @override
  String get settingsShortcutBody =>
      'Press these keys in any app to open or close Ferret\'s menu.';

  @override
  String get settingsShortcutOff => 'Off';

  @override
  String get settingsShortcutChange => 'Change';

  @override
  String get settingsShortcutTurnOff => 'Turn off';

  @override
  String get settingsShortcutTurnOn => 'Turn on';

  @override
  String get settingsShortcutRecording => 'Press the new keys. Esc cancels.';

  @override
  String get settingsShortcutTaken =>
      'macOS didn\'t take these keys. Try others.';

  @override
  String deviceMay(String device) {
    return '$device may';
  }

  @override
  String get deviceHow => 'How?';

  @override
  String get deviceFix => 'Fix';

  @override
  String activityActionFor(String action, String subject) {
    return '$action: $subject';
  }

  @override
  String healthActionFor(String action, String feature) {
    return '$action $feature';
  }

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
  String get qrScanEnough =>
      'Scanning is enough, with Ferret or the phone\'s camera. No code to compare.';

  @override
  String get qrWaiting => 'Waiting for your phone…';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offline',
    );
    return '$_temp0';
  }

  @override
  String get devicesShow => 'Show';

  @override
  String get devicesPin => 'Pin to Top';

  @override
  String get devicesUnpin => 'Unpin';

  @override
  String get devicePinned => 'Pinned';

  @override
  String devicesStale(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not seen in 30 days',
      one: '1 not seen in 30 days',
    );
    return '$_temp0';
  }

  @override
  String get devicesStaleReview => 'Remove…';

  @override
  String devicesStaleConfirm(String names, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Remove $names from $_temp0?';
  }

  @override
  String get devicesStaleConfirmBody =>
      'Not seen in 30 days. Your other devices keep them, and you can pair them again any time.';

  @override
  String get devicesStaleRemove => 'Remove';

  @override
  String get deviceRename => 'Rename…';

  @override
  String deviceRenameTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Name on $_temp0';
  }

  @override
  String deviceRenameBody(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Only $_temp0 uses this name. $device keeps its own.';
  }

  @override
  String get deviceRenameSave => 'Save';

  @override
  String get deviceRenameReset => 'Use its own name';

  @override
  String deviceSameName(String name) {
    return 'Another of your devices is also called $name. Give this one a name you\'ll recognise.';
  }

  @override
  String deviceOwnName(String name) {
    return 'Calls itself $name';
  }

  @override
  String get activityFilterAll => 'All';

  @override
  String joinedManyNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices joined your devices',
      one: '1 device joined your devices',
    );
    return '$_temp0';
  }

  @override
  String joinedManyBanner(String names) {
    return '$names joined your devices';
  }

  @override
  String joinedManyAddedBy(String introducer) {
    return 'Added by $introducer';
  }

  @override
  String get joinedReview => 'Review';

  @override
  String get joinedKeepAll => 'Keep all';

  @override
  String get sidebarFind => 'Find a device';

  @override
  String sidebarNoMatch(String query) {
    return 'No device called “$query”';
  }

  @override
  String dropOfflineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offline',
      one: '1 offline',
    );
    return '$_temp0';
  }

  @override
  String get emptyBody =>
      'Install Ferret on your other device too, and open it. It shows up here when both are on the same Wi-Fi. An iPhone pairs with a QR code instead.';

  @override
  String get emptyBodyIphone =>
      'Install Ferret on your computer too, and open it. Then scan the code it shows.';

  @override
  String get emptyCantSee => 'Can\'t see it?';

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
  String get activityQuickLook => 'Quick Look';

  @override
  String get needsYouTitle => 'Needs you';

  @override
  String get activityEmpty => 'Nothing yet. Copy something or send a file.';

  @override
  String get activityNow => 'now';

  @override
  String activityMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
    );
    return '$_temp0';
  }

  @override
  String activityHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h',
    );
    return '$_temp0';
  }

  @override
  String activityDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count d',
    );
    return '$_temp0';
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
  String get tipPaste =>
      'Tired of the Allow Paste question? Settings → Ferret → Paste from Other Apps → Allow';

  @override
  String get tipPasteOpen => 'Open Settings';

  @override
  String get doctorFirewall =>
      'Windows Firewall may be blocking Ferret.\n1. Tap Allow through firewall, then Yes when Windows asks.\n2. Try again.\nOr tap Open Windows Firewall, then Change settings, and tick Ferret.';

  @override
  String get doctorFixOpenFirewall => 'Open Windows Firewall';

  @override
  String get sidebarHide => 'Hide sidebar';

  @override
  String get sidebarShow => 'Show sidebar';

  @override
  String get activityPaneHide => 'Hide Activity';

  @override
  String get activityPaneShow => 'Show Activity';

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
  String get menuTakePhoto => 'Take Photo';

  @override
  String menuTakePhotoWith(String device) {
    return 'Take Photo with $device';
  }

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

  @override
  String get doctorFirewallAllowed =>
      'Windows Firewall lets Ferret in on private networks. Still hidden? Make sure this network is set to Private: Settings → Network & internet → your Wi-Fi.';

  @override
  String get doctorFixAllowFirewall => 'Allow through firewall';

  @override
  String get traySendClipboard => 'Send clipboard to my devices';

  @override
  String get trayStillRunningTitle => 'Ferret is still running';

  @override
  String get trayStillRunningBody =>
      'Find it in the tray, next to the clock. Quit from its menu.';

  @override
  String get noticeChannelTransfers => 'Transfers';

  @override
  String get noticeChannelIncoming => 'From your devices';

  @override
  String get noticeChannelSuggestions => 'Continue suggestions';

  @override
  String get noticeChannelFind => 'Find';

  @override
  String get noticeChannelProblems => 'Connection problems';

  @override
  String get settingsStartAtLogin => 'Start Ferret when I log in';

  @override
  String settingsStartAtLoginBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'It opens in the menu bar, so your devices connect before you need them.',
        'other': 'It starts in the tray, so your devices connect before you need them.',
      },
    );
    return '$_temp0';
  }

  @override
  String get menuHelp => 'Help';

  @override
  String get menuKeyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get menuCheckNetwork => 'Check My Network…';

  @override
  String get menuSponsor => 'Sponsor Ferret…';

  @override
  String get shortcutsTitle => 'Keyboard shortcuts';

  @override
  String get shortcutSections => 'Sections of the selected device';

  @override
  String get shortcutSidebar => 'Show or hide the device list';

  @override
  String get shortcutActivityPane => 'Show or hide the Activity pane';

  @override
  String get shortcutsInWindow => 'In the window';

  @override
  String get shortcutsAnyApp => 'From any app';

  @override
  String get shortcutRecentClips => 'Recent clips';

  @override
  String accessTitle(String device) {
    return 'What $device can use';
  }

  @override
  String accessIntro(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '$device reaches $_temp0 only through what\'s on here, directly on your network. Turn one off and it stops right away, on both devices.';
  }

  @override
  String accessOffline(String device) {
    return '$device is offline. What you change applies before it can use anything again.';
  }

  @override
  String get accessSummaryAll => 'Everything on';

  @override
  String get accessSummaryNone => 'Everything off';

  @override
  String accessSummarySome(int off, int total) {
    return '$off of $total off';
  }

  @override
  String get accessTurnAllOff => 'Turn everything off';

  @override
  String get accessTurnAllOn => 'Turn all back on';

  @override
  String accessForgetHint(String device) {
    return 'Turning everything off keeps $device paired. To stop it connecting at all, forget it at the bottom of its page.';
  }

  @override
  String get accessClipboard => 'What you copy, both ways';

  @override
  String get accessDrop => 'Files and links you send, both ways';

  @override
  String get accessNotifications =>
      'A phone\'s notifications, and the replies and actions you send back';

  @override
  String get accessMessages =>
      'A phone\'s texts and contacts\' names, and texts you send from a computer';

  @override
  String get accessCalls =>
      'Who is calling, recent calls, answering and placing calls';

  @override
  String get accessHandoff =>
      'The page or thing you were on, to continue it on the other device';

  @override
  String get accessMedia =>
      'What\'s playing, and play, pause and skip from the other device';

  @override
  String get accessMirroring =>
      'Showing a phone\'s screen, each time only after the phone says yes';

  @override
  String get accessRemoteInput =>
      'Moving the pointer and typing, only after you allow it';

  @override
  String get accessFind => 'Ringing a device to find it';

  @override
  String get accessActions =>
      'Sleep, restart, shut down, volume and your own actions, each only after you allow it';

  @override
  String menubarTipControlled(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return '$device is controlling $_temp0';
  }

  @override
  String menubarTipScreenSeen(String device) {
    return '$device can see this screen';
  }

  @override
  String get deviceUpdateThere => 'Needs a newer Ferret';

  @override
  String get deviceUpdateHere => 'Update Ferret here to connect';

  @override
  String updateThereTitle(String name) {
    return 'Update Ferret on $name';
  }

  @override
  String updateThereBody(String name, String version, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '$name has an older Ferret ($version) that $_temp0 can\'t talk to anymore. Update it from where you installed it, then open it once. They connect again by themselves.';
  }

  @override
  String updateHereTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Update Ferret on $_temp0';
  }

  @override
  String updateHereBody(String name, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '$name has a newer Ferret that $_temp0 can\'t talk to yet. Update Ferret here, and they connect again by themselves.';
  }

  @override
  String get updateGet => 'Get the update';

  @override
  String replaceTitle(String name) {
    return 'Is this your new $name?';
  }

  @override
  String replaceBody(String old) {
    return '$old hasn\'t been seen since. Replace it, and it goes from all your devices, while this one keeps its name, pin and what it may use.';
  }

  @override
  String get replaceAction => 'Replace old one';

  @override
  String get replaceKeepBoth => 'Keep both';

  @override
  String whatsNewLine(String version) {
    return 'Updated to Ferret $version';
  }

  @override
  String get whatsNewAction => 'What\'s new';

  @override
  String get settingsTipsAgain => 'Show tips again';

  @override
  String get settingsTipsAgainDetail =>
      'The short hints at the top of Ferret, such as how to copy across.';

  @override
  String get settingsTipsAgainDone => 'Tips are back, one at a time.';

  @override
  String get settingsPrivacyPerDevice =>
      'To choose what one device can use, open that device and look under What it can use.';

  @override
  String get deviceAway => 'Connected · locked';

  @override
  String doctorHotspot(String phone, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'No shared Wi-Fi? Turn on $phone\'s hotspot and join it from $_temp0. Ferret works over it, and what goes between your devices uses no mobile data.';
  }

  @override
  String doctorHotspotAny(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'your other device',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'No shared Wi-Fi? Turn on your phone\'s hotspot and join it from $_temp0. Ferret works over it, and what goes between your devices uses no mobile data.';
  }

  @override
  String doctorHotspotHere(String device) {
    return 'No shared Wi-Fi? Turn on this phone\'s hotspot and join it from $device. Ferret works over it, and what goes between your devices uses no mobile data.';
  }

  @override
  String webcamRow(String device) {
    return 'Use $device as a webcam';
  }

  @override
  String webcamTitle(String device) {
    return '$device as a webcam';
  }

  @override
  String get webcamIntro =>
      'Many Android phones with Android 14 or later can be a USB webcam all by themselves. No app, no driver.';

  @override
  String webcamSteps(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'this Mac',
        'phone': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '1. Plug $device into $_temp0 with a USB cable.\n2. On $device, pull down from the top and tap the USB notification.\n3. Choose Webcam.\n4. In your video app, pick the phone as the camera.';
  }

  @override
  String webcamMissing(String device) {
    return 'No Webcam in that list? $device doesn\'t have it yet. Pixel phones from the Pixel 6 on do.';
  }

  @override
  String webcamOverWifi(String device) {
    return 'No cable? Use $device\'s camera sends it over Wi-Fi, into a Ferret window. Video apps can\'t pick it from there yet.';
  }

  @override
  String batteryLevel(String percent) {
    return 'Battery $percent';
  }

  @override
  String batteryCharging(String percent) {
    return 'Battery $percent, charging';
  }

  @override
  String lowBatteryTitle(String device, int percent) {
    return '$device is at $percent%';
  }

  @override
  String get lowBatteryBody => 'Plug it in soon to keep it connected.';

  @override
  String get settingsLowBattery => 'Low battery notice';

  @override
  String get settingsLowBatteryBody =>
      'Says once when one of your devices drops to 15%.';

  @override
  String get vpnRow => 'Reach away from home';

  @override
  String vpnTitle(String device) {
    return 'Reach $device away from home';
  }

  @override
  String vpnIntro(String device) {
    return 'Not on the same Wi-Fi? If $device and this device are both on your own VPN, such as Tailscale, ZeroTier or WireGuard, Ferret can reach it there. No Ferret account, no Ferret server: the VPN is yours.';
  }

  @override
  String vpnSwitch(String device) {
    return 'Also reach $device over your VPN';
  }

  @override
  String get vpnSwitchHint =>
      'Ferret tries your local network first, every time. Off, it never leaves it.';

  @override
  String get vpnReachAt => 'Reach at';

  @override
  String get vpnReachAtHint => '100.101.102.103 or pixel.tail1234.ts.net';

  @override
  String get vpnSaveAddress => 'Save address';

  @override
  String vpnAddresses(String device, String addresses) {
    return '$device shared its VPN addresses: $addresses. The address above is optional.';
  }

  @override
  String vpnNoAddresses(String device) {
    return '$device hasn\'t shared its VPN addresses yet. It does the next time it connects, if it\'s on a VPN. Or type its address above.';
  }

  @override
  String get vpnSlow => 'Large files may take longer than at home.';

  @override
  String vpnPrivacy(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'This Mac\'s',
        'phone': 'This phone\'s',
        'tablet': 'This tablet\'s',
        'other': 'This computer\'s',
      },
    );
    return 'This asks $device for its VPN addresses. $_temp0 own go only to devices that have this switch on for it.';
  }

  @override
  String get deviceReachedOverVpn => 'Reached over your VPN';

  @override
  String doctorVpnReachOn(String device) {
    return 'Ferret also tries $device over your VPN. Make sure the VPN is on, on both devices.';
  }

  @override
  String doctorVpnReachOff(String device) {
    return 'Away from home? If $device is on your VPN too, Ferret can reach it there.';
  }

  @override
  String get doctorFixReachOverVpn => 'Reach over your VPN';

  @override
  String get iconDropChoose => 'Choose a device';

  @override
  String get iconDropShelf => 'Put on the shelf';

  @override
  String get iconDropKept => 'On the shelf';

  @override
  String iconDropSending(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sending $count files to $name',
      one: 'Sending to $name',
    );
    return '$_temp0';
  }

  @override
  String get iconDropUndo => 'Undo';

  @override
  String get localNetworkTitle => 'Find your devices';

  @override
  String get localNetworkBody =>
      'Ferret finds and talks to your own devices on this Wi-Fi. Android asks before any app can, so Ferret needs your OK. Nothing leaves your network.';

  @override
  String get localNetworkAllow => 'Allow';

  @override
  String get localNetworkAllowTooltip =>
      'Let Ferret reach your devices on this Wi-Fi';

  @override
  String get localNetworkBlocked =>
      'Android won\'t ask again. In Settings, open Permissions, then Nearby devices, and pick Allow.';

  @override
  String get localNetworkOpenSettings => 'Open Settings';

  @override
  String get localNetworkOpenSettingsTooltip =>
      'Open Ferret\'s page in Android Settings';

  @override
  String get doctorLocalNetwork =>
      'Ferret isn\'t allowed on this Wi-Fi yet, so it can\'t find or reach your devices. Android asks before any app can.';

  @override
  String get doctorLocalNetworkBlocked =>
      'Ferret isn\'t allowed on this Wi-Fi, and Android won\'t ask again. In Settings, open Permissions, then Nearby devices, and pick Allow.';

  @override
  String get doctorLocalNetworkMac =>
      'macOS is blocking Ferret on the local network, so it can\'t find or reach your devices. Open System Settings, then Privacy & Security, then Local Network, and turn on Ferret.';

  @override
  String get doctorFixAllowLocalNetwork => 'Allow on this Wi-Fi';
}
