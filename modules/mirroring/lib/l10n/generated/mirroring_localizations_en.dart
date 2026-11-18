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
  String windowTitle(String device) {
    return '$device — Screen';
  }

  @override
  String inWindowTitle(String device) {
    return '$device\'s screen has its own window';
  }

  @override
  String get bringToFront => 'Bring to front';

  @override
  String launcherTitle(String device) {
    return 'See $device\'s screen on this computer';
  }

  @override
  String launcherBody(String device) {
    return '$device asks you every time, unless it is on a cable you allowed.';
  }

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
  String get fullScreen => 'Full screen';

  @override
  String get exitFullScreen => 'Exit full screen';

  @override
  String requestingTitle(String device) {
    return 'Asking $device…';
  }

  @override
  String waitingTitle(String device) {
    return 'Answer on $device';
  }

  @override
  String waitingBody(String device) {
    return 'On $device, choose to share the entire screen, then Start.';
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
    return 'Someone tapped Cancel on $device.';
  }

  @override
  String endTimedOutTitle(String device) {
    return 'Nobody answered on $device';
  }

  @override
  String endTimedOutBody(String device) {
    return 'The question stays on $device for a minute. Wake $device, then ask again.';
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
    return 'On $device: open Ferret, or allow its notifications. Then ask again.';
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
    return 'On $device: open Ferret. Same Wi-Fi as this computer?';
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
    return 'Android stops sharing when $device locks, or when someone stops it from the status bar. Unlock $device, then show it again.';
  }

  @override
  String endLostConnectionTitle(String device) {
    return 'Lost the connection to $device';
  }

  @override
  String endLostConnectionBody(String device) {
    return 'Check that $device is on, and on the same Wi-Fi as this computer.';
  }

  @override
  String get endFailedTitle => 'The picture stopped';

  @override
  String endFailedBody(String device) {
    return '$device couldn\'t capture its screen.';
  }

  @override
  String get endDecoderFailedTitle =>
      'This computer couldn\'t show the picture';

  @override
  String endDecoderFailedBody(String device) {
    return 'The video from $device didn\'t play here.';
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
  String get targetCable => 'Cable';

  @override
  String get targetWireless => 'Wi-Fi debugging';

  @override
  String get setupInstallToolBody =>
      'Install Android\'s platform tools (they include adb) on this computer. This page moves on by itself.';

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
      'Ferret isn\'t allowed to start adb on this computer. Open Android Studio, or run adb start-server in Terminal. This page moves on by itself.';

  @override
  String get setupPermissionTitle => 'Ferret needs your OK on this computer';

  @override
  String get setupPermissionBody =>
      'Allow Ferret under Local Network in this computer\'s privacy settings.';

  @override
  String get buttonBack => 'Back';

  @override
  String get buttonHome => 'Home';

  @override
  String get buttonRecents => 'Recents';

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
  String get allow => 'Show';

  @override
  String get dontAllow => 'Don\'t allow';

  @override
  String get close => 'Close';

  @override
  String get showAgain => 'Show again';

  @override
  String get askAgain => 'Ask again';

  @override
  String askAgainIn(String time) {
    return 'You can ask again in $time.';
  }

  @override
  String get how => 'How';

  @override
  String get why => 'Why?';

  @override
  String get wake => 'Wake';

  @override
  String get notMine => 'Not mine';

  @override
  String get showIt => 'Show';

  @override
  String startingCableTitle(String device) {
    return 'Showing $device…';
  }

  @override
  String waitingNothing(String device) {
    return 'Nothing on $device? Open the notice from Ferret.';
  }

  @override
  String get waitingWhy =>
      'Android asks every time. Ferret can\'t skip it, and wouldn\'t.';

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String reconnectingTitle(String device) {
    return 'Reconnecting to $device…';
  }

  @override
  String lostTitle(String device) {
    return 'Lost $device';
  }

  @override
  String lostBody(String device) {
    return 'This picks up again when $device is back.';
  }

  @override
  String lostCableBody(String device) {
    return 'Plug $device back in. The picture picks up by itself.';
  }

  @override
  String notConnectedWaits(String device) {
    return 'This starts by itself when $device connects.';
  }

  @override
  String get orDivider => 'or';

  @override
  String plugInTitle(String device) {
    return 'Plug $device into this computer';
  }

  @override
  String get plugInBody => 'You can click and type on it too.';

  @override
  String get buttonRotate => 'Rotate';

  @override
  String get buttonKeyboard => 'Keyboard';

  @override
  String get buttonNotifications => 'Notifications panel';

  @override
  String get buttonVolumeUp => 'Volume up';

  @override
  String get buttonVolumeDown => 'Volume down';

  @override
  String get buttonPower => 'Power';

  @override
  String get more => 'More';

  @override
  String tooltipWithKey(String name, String key) {
    return '$name ($key)';
  }

  @override
  String get keyRightClick => 'right-click';

  @override
  String get keyMiddleClick => 'middle-click';

  @override
  String get viewOnly => 'View only';

  @override
  String viewOnlyBody(String device) {
    return '$device shares its picture, not its controls. To click and type, plug it in.';
  }

  @override
  String get viewOnlyAirplayBody =>
      'An iPhone or iPad shares its picture, not its controls.';

  @override
  String get controlWithCable => 'Control with the cable';

  @override
  String get viewOnlyToast => 'View only.';

  @override
  String get keepToolbar => 'Keep toolbar visible';

  @override
  String get qualityGood => 'Good';

  @override
  String get qualitySlow => 'Slow';

  @override
  String get qualityPoor => 'Poor';

  @override
  String get pictureTitle => 'Picture';

  @override
  String get presetAuto => 'Auto';

  @override
  String get presetAutoBody => 'Ferret adapts';

  @override
  String get presetSharp => 'Sharp';

  @override
  String get presetSharpBody => 'Full size';

  @override
  String get presetFast => 'Fast';

  @override
  String get presetFastBody => 'Smaller, smooth';

  @override
  String get presetRestarts => 'Changing it restarts the picture.';

  @override
  String presetNextTime(String device) {
    return '$device has to say yes again for a change, so it applies next time.';
  }

  @override
  String get presetAirplay => 'The iPhone picks the quality.';

  @override
  String get basicPicture =>
      'Basic picture on this computer for now (about 10 a second).';

  @override
  String get details => 'Details';

  @override
  String get wayWifi => 'Wi-Fi';

  @override
  String get wayCable => 'Cable';

  @override
  String get wayAirplay => 'AirPlay';

  @override
  String get noticeViaCable => 'Showing over the cable instead.';

  @override
  String noticeCableNoAsk(String device) {
    return 'Over a cable, $device doesn\'t ask each time. Only do this with your own phone.';
  }

  @override
  String noticeSlow(String device) {
    return 'Slow connection to $device.';
  }

  @override
  String noticeSlowHelp(String device) {
    return 'Slow connection to $device. Move closer to the Wi-Fi, or plug it in.';
  }

  @override
  String get useFast => 'Use Fast';

  @override
  String get textFieldHint => 'Type or paste, then press Enter';

  @override
  String get send => 'Send';

  @override
  String replaceTitle(String current, String next) {
    return 'Stop showing $current and show $next?';
  }

  @override
  String replaceConfirm(String device) {
    return 'Show $device';
  }

  @override
  String leaveTitle(String device) {
    return 'Stop showing $device?';
  }

  @override
  String get leaveBody => 'Leaving this page stops sharing on both devices.';

  @override
  String get keepShowing => 'Keep showing';

  @override
  String setupTitle(String device) {
    return 'Show $device with a cable';
  }

  @override
  String get setupSubtitle => 'No app needed on the phone.';

  @override
  String get stepPlug => 'Plug the phone into this computer';

  @override
  String get stepDebugging => 'Turn on USB debugging';

  @override
  String get stepDebuggingOn => 'On the phone:';

  @override
  String get stepDebugging1 => 'Settings → About phone';

  @override
  String get stepDebugging2 => 'Tap Build number 7 times';

  @override
  String get stepDebugging3 =>
      'Settings → System → Developer options → USB debugging';

  @override
  String get brandsToggle => 'Samsung, Xiaomi, others';

  @override
  String get brandsBody =>
      'Samsung: Build number is under About phone → Software information.\nXiaomi: tap the OS version instead of Build number, and also turn on USB debugging (Security settings), or clicks won\'t work.\nAny other phone: search its Settings for Build number.';

  @override
  String get stepAllow => 'Tap Allow on the phone';

  @override
  String stepAllowNamed(String device) {
    return 'On $device: tap Allow. Tick Always allow from this computer.';
  }

  @override
  String get setupWaiting => 'Waiting for the phone…';

  @override
  String get setupCables => 'Many cables only charge. Try another one.';

  @override
  String get setupPrivacy =>
      'Once allowed, this computer can see and control the phone without asking. Only do this with your own phone.';

  @override
  String get setupUnsupported =>
      'This computer can\'t show a phone over a cable.';

  @override
  String airplayOn(String device) {
    return 'On $device:';
  }

  @override
  String get airplayStep1 =>
      'Open Control Center (swipe down from the top right)';

  @override
  String get airplayStep2 => 'Tap Screen Mirroring';

  @override
  String airplayStep3(String computer) {
    return 'Pick “$computer”';
  }

  @override
  String get airplayListening => 'Listening…';

  @override
  String get airplayNote =>
      'View only. No sound. Experimental: an iOS update can break it.';

  @override
  String get airplayMacTitle => 'Macs already do this';

  @override
  String airplayMacBody(String device) {
    return 'On $device, pick this Mac under Screen Mirroring, or use iPhone Mirroring.';
  }

  @override
  String get useFerretAnyway => 'Use Ferret anyway';

  @override
  String airplayConnecting(String device) {
    return '$device is connecting';
  }

  @override
  String get airplayConnectingBody =>
      'The name is what the device calls itself. Say yes only if it is yours.';

  @override
  String get airplayTimedOutTitle => 'Nobody picked this computer';

  @override
  String get airplayTimedOutBody =>
      'Ferret listened for two minutes, then stopped.';

  @override
  String get listenAgain => 'Listen again';

  @override
  String viewingDetail(String time, String way) {
    return 'Since $time · $way';
  }

  @override
  String viewingAsking(String device) {
    return 'Asking $device…';
  }

  @override
  String get lookForCableTitle => 'Look for phones on a cable';

  @override
  String get lookForCableBody =>
      'Shows any Android phone plugged in with USB debugging on.';

  @override
  String get summaryCable => 'Looks for a cable';

  @override
  String sharingReconnecting(String device) {
    return '$device dropped off. Waiting a moment for it to come back.';
  }

  @override
  String get endStoppedHereTitle => 'Stopped';

  @override
  String endStoppedHereBody(String device) {
    return '$device no longer shares its screen.';
  }

  @override
  String get allowNoticeBody => 'Say yes only if it is yours.';
}
