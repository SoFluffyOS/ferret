// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'mirroring_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class MirroringLocalizationsEn extends MirroringLocalizations {
  MirroringLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Screen';

  @override
  String get showScreen => 'Show screen';

  @override
  String get stop => 'Stop';

  @override
  String get cancel => 'Cancel';

  @override
  String get tryAgain => 'Try again';

  @override
  String get back => 'Back';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get open => 'Open';

  @override
  String get fit => 'Fit';

  @override
  String get actualSize => '1:1';

  @override
  String get fitTooltip => 'Fit the picture to the window';

  @override
  String get actualSizeTooltip => 'One phone pixel per screen pixel';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get exitFullScreen => 'Exit full screen';

  @override
  String requestingTitle(String device) {
    return 'Asking $device…';
  }

  @override
  String get requestingBody => 'This takes a moment.';

  @override
  String waitingTitle(String device) {
    return 'Answer on $device';
  }

  @override
  String waitingBody(String device) {
    return 'On $device: Android asks whether to share the screen. Tap Start. If $device shows nothing, open the notice from Ferret.';
  }

  @override
  String startingTitle(String device) {
    return '$device said yes';
  }

  @override
  String get startingBody => 'Waiting for the first picture…';

  @override
  String screenOffTitle(String device) {
    return '$device\'s screen is off';
  }

  @override
  String screenOffBody(String device) {
    return 'Wake $device to see it again.';
  }

  @override
  String endDeniedTitle(String device) {
    return '$device said no';
  }

  @override
  String endDeniedBody(String device) {
    return 'Someone tapped Cancel on $device. You can ask again in half a minute.';
  }

  @override
  String endTimedOutTitle(String device) {
    return 'Nobody answered on $device';
  }

  @override
  String endTimedOutBody(String device) {
    return 'The question stays on $device for a minute. Wake $device, then try again.';
  }

  @override
  String endBusyTitle(String device) {
    return '$device is already sharing its screen';
  }

  @override
  String get endBusyBody =>
      'A phone shares its screen with one device at a time. Stop the other one first.';

  @override
  String endUnsupportedTitle(String device) {
    return '$device can\'t share its screen';
  }

  @override
  String get endUnsupportedBody =>
      'Showing a screen needs an Android phone with Ferret.';

  @override
  String endTurnedOffTitle(String device) {
    return 'Screen sharing is off on $device';
  }

  @override
  String endTurnedOffBody(String device) {
    return 'On $device: open Ferret → Settings → To your computer and turn on Let my computers ask to see this screen. Then open this computer there and check that it may ask.';
  }

  @override
  String endCannotAskTitle(String device) {
    return '$device couldn\'t show the question';
  }

  @override
  String endCannotAskBody(String device) {
    return 'On $device: open Ferret, or allow its notifications. Then try again.';
  }

  @override
  String endVersionTitle(String device) {
    return '$device needs a newer Ferret';
  }

  @override
  String endVersionBody(String device) {
    return 'Update Ferret on $device, then try again.';
  }

  @override
  String endNoCodecTitle(String device) {
    return '$device can\'t send a picture this computer can show';
  }

  @override
  String endNoCodecBody(String device) {
    return 'Update Ferret on $device and on this computer, then try again.';
  }

  @override
  String endNotConnectedTitle(String device) {
    return '$device isn\'t connected';
  }

  @override
  String endNotConnectedBody(String device) {
    return 'On $device: open Ferret. Check that $device and this computer are on the same Wi-Fi.';
  }

  @override
  String endNoAnswerTitle(String device) {
    return '$device didn\'t answer';
  }

  @override
  String endNoAnswerBody(String device) {
    return 'On $device: open Ferret. Then try again.';
  }

  @override
  String get endStoppedHereTitle => 'Stopped on this computer';

  @override
  String endStoppedHereBody(String device) {
    return '$device no longer shares its screen.';
  }

  @override
  String endStoppedOnPhoneTitle(String device) {
    return 'Stopped on $device';
  }

  @override
  String endStoppedOnPhoneBody(String device) {
    return 'Someone tapped Stop on $device.';
  }

  @override
  String endSystemEndedTitle(String device) {
    return '$device stopped sharing';
  }

  @override
  String endSystemEndedBody(String device) {
    return 'Android ends screen sharing when $device locks, or when someone stops it from the status bar.';
  }

  @override
  String endLostConnectionTitle(String device) {
    return 'Lost the connection to $device';
  }

  @override
  String endLostConnectionBody(String device) {
    return 'Ferret reconnects on its own. Try again once $device is back.';
  }

  @override
  String get endFailedTitle => 'The picture stopped';

  @override
  String endFailedBody(String device) {
    return '$device couldn\'t capture its screen. Try again.';
  }

  @override
  String get endDecoderFailedTitle =>
      'This computer couldn\'t show the picture';

  @override
  String endDecoderFailedBody(String device) {
    return 'The video from $device didn\'t play here. Try again.';
  }

  @override
  String statusPicture(String codec, int width, int height, int fps) {
    return '$codec · $width×$height · $fps fps';
  }

  @override
  String statusLatency(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String statusBitrate(String megabits) {
    return '$megabits Mbps';
  }

  @override
  String statusDropped(int count) {
    return '$count dropped';
  }

  @override
  String get codecH264 => 'H.264';

  @override
  String get codecJpeg => 'JPEG';

  @override
  String viewingTitle(String device) {
    return 'Showing $device\'s screen';
  }

  @override
  String viewingWaitingTitle(String device) {
    return 'Waiting for $device';
  }

  @override
  String viewingWaitingBody(String device) {
    return 'On $device: answer Android\'s prompt.';
  }

  @override
  String sinceTime(String time) {
    return 'Since $time';
  }

  @override
  String sharingTitle(String device) {
    return 'Sharing screen with $device';
  }

  @override
  String sharingBody(String time) {
    return 'Everything on this screen is visible there. Since $time.';
  }

  @override
  String askingTitle(String device) {
    return '$device wants to see this screen';
  }

  @override
  String get askingBody =>
      'Answer Android\'s prompt. If you don\'t see it, tap the notice from Ferret.';

  @override
  String auditShared(String device, String duration, String time) {
    return '$device saw this phone\'s screen for $duration at $time';
  }

  @override
  String auditViewed(String device, String duration, String time) {
    return 'You viewed $device\'s screen for $duration at $time';
  }

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds s',
      one: '1 s',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get noticeAskBody => 'Tap to answer';

  @override
  String get noticeAskChannel => 'Screen sharing requests';

  @override
  String get noticeSharingBody => 'Everything on this screen is visible there';

  @override
  String get noticeSharingChannel => 'Screen sharing';

  @override
  String get settingsAllow => 'Let my computers ask to see this screen';

  @override
  String get settingsAllowBody =>
      'Android asks you every time. Nothing is shared before you say yes.';

  @override
  String get settingsUnsupported => 'This phone can\'t capture its screen';

  @override
  String get settingsScreenOffNote =>
      'Turning the phone\'s screen off while it is mirrored needs root, so Ferret doesn\'t offer it.';

  @override
  String get settingsViewerHint =>
      'Open a connected Android phone and choose Show screen. The phone asks its owner every time.';

  @override
  String get settingsHistoryTitle => 'History';

  @override
  String get settingsHistoryEmptyShared => 'Nobody has seen this screen yet.';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get settingsPerDevice =>
      'To stop one computer from asking, open it from Home.';

  @override
  String get summaryOff => 'Off';

  @override
  String get summaryAsks => 'Asks every time';

  @override
  String get summaryCantCapture => 'Can\'t capture';

  @override
  String get summaryMoreWays => 'More ways on';

  @override
  String get permissionAsk => 'Ask to see this phone\'s screen';

  @override
  String get permissionAskOff =>
      'Screen is off for every computer. Turn it on in Settings → To your computer.';

  @override
  String healthAsks(String device) {
    return 'Asks on $device every time';
  }

  @override
  String get healthTryAgainHelp => 'Choose Show screen to try again.';

  @override
  String get healthShareOff => 'Off on this phone';

  @override
  String get healthShareOffHelp =>
      'Open Settings → To your computer and turn on Let my computers ask to see this screen.';

  @override
  String healthShareBlocked(String device) {
    return 'Off for $device';
  }

  @override
  String healthShareBlockedHelp(String device) {
    return 'Turn on Ask to see this phone\'s screen for $device, further down this page.';
  }

  @override
  String get healthSharing => 'Sees this phone\'s screen now';

  @override
  String get healthShareAsks => 'Asks you every time';

  @override
  String get healthViewing => 'Showing its screen here';

  @override
  String healthTurnedOff(String device) {
    return 'Off on $device';
  }

  @override
  String healthUnsupported(String device) {
    return '$device can\'t share its screen';
  }

  @override
  String healthCannotAsk(String device) {
    return '$device couldn\'t show the question';
  }

  @override
  String healthFailed(String device) {
    return '$device couldn\'t capture its screen';
  }

  @override
  String get healthDecoderFailed => 'This computer couldn\'t show the picture';

  @override
  String get experimental => 'Experimental';

  @override
  String get moreWaysTitle => 'More ways to show a screen';

  @override
  String get moreWaysBody =>
      'Also show a phone plugged in with a cable, and screens other devices send here themselves. This is new, so expect rough edges.';

  @override
  String get moreWaysOffer =>
      'Experimental: show a phone plugged in with a cable, or a screen another device sends here.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get targetsTitle => 'Screens you can show';

  @override
  String get targetsSubtitle =>
      'Found by the experimental ways. They don\'t need Ferret.';

  @override
  String get targetCable => 'Plugged in with a cable';

  @override
  String get targetWireless => 'On your network';

  @override
  String get show => 'Show screen';

  @override
  String get checkAgain => 'Check again';

  @override
  String get setupInstallToolTitle =>
      'This computer needs a small helper first';

  @override
  String get setupInstallToolBody =>
      'How to: install Android\'s platform tools (they include adb) on this computer, then try again.';

  @override
  String get setupDownloadToolTitle => 'Get Android\'s helper tool';

  @override
  String get setupDownloadToolBody =>
      'Ferret downloads Android\'s platform tools from Google, about 16 MB, once.';

  @override
  String get download => 'Download';

  @override
  String get downloading => 'Downloading…';

  @override
  String get setupDownloadFailed =>
      'The download didn\'t finish. Check this computer\'s internet connection and try again.';

  @override
  String get setupStartToolTitle => 'Start Android\'s helper tool';

  @override
  String get setupStartToolBody =>
      'Ferret isn\'t allowed to start adb on this computer. Open Android Studio, or run adb start-server in Terminal, then check again.';

  @override
  String get setupEnableDebuggingTitle =>
      'The phone needs one setting turned on';

  @override
  String get setupEnableDebuggingBody =>
      'On the phone: open Settings, then About phone, and tap Build number seven times. Then turn on USB debugging in Developer options.';

  @override
  String get setupAuthorizeTitle => 'Allow this computer on the phone';

  @override
  String get setupAuthorizeBody =>
      'On the phone: tap Allow on the question it shows. Then try again.';

  @override
  String get setupPermissionTitle => 'Ferret needs your OK on this computer';

  @override
  String get setupPermissionBody =>
      'How to: allow Ferret under Local Network in this computer\'s privacy settings, then try again.';

  @override
  String get buttonBack => 'Back';

  @override
  String get buttonHome => 'Home';

  @override
  String get buttonRecents => 'Recent apps';

  @override
  String get receiverAirplayTitle => 'Show iPhone and iPad screens here';

  @override
  String get receiverAirplayBody =>
      'This computer appears under Screen Mirroring in the iPhone\'s Control Center. You are asked before anything shows.';

  @override
  String get receiverOtherTitle => 'Let other devices send their screen here';

  @override
  String get receiverOtherBody => 'You are asked before anything shows.';

  @override
  String allowTitle(String device) {
    return '$device wants to show its screen here';
  }

  @override
  String get allowBody =>
      'Say yes only if this is your device. The name is what the device calls itself, and anyone on your network can ask.';

  @override
  String get allow => 'Allow';

  @override
  String get dontAllow => 'Don\'t allow';
}
