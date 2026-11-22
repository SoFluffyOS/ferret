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
  String launcherTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'See $device\'s screen on $_temp0';
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
  String endTurnedOffBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'On $device: open Ferret → Settings → To your computer and turn on Let my computers ask to see this screen. Then open $_temp0 there and check that it may ask.';
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
  String endNoCodecTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return '$device can\'t send a picture $_temp0 can show';
  }

  @override
  String endNoCodecBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Update Ferret on $device and on $_temp0, then try again.';
  }

  @override
  String endNotConnectedTitle(String device) {
    return '$device isn\'t connected';
  }

  @override
  String endNotConnectedBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'On $device: open Ferret. Same Wi-Fi as $_temp0?';
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
  String endLostConnectionBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Check that $device is on, and on the same Wi-Fi as $_temp0.';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dropped',
    );
    return '$_temp0';
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
  String auditShared(String device, String duration, String time, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return '$device saw $_temp0 screen for $duration at $time';
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
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours h',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
    );
    return '$_temp0 $_temp1';
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
  String sharingTitleSound(String device) {
    return 'Sharing screen and sound with $device';
  }

  @override
  String sharingBodySound(String time) {
    return 'Everything on this screen is visible there, with sound. Since $time.';
  }

  @override
  String get noticeSharingBodySound =>
      'Everything on this screen is visible there, with sound';

  @override
  String get settingsSendSound => 'Send sound too';

  @override
  String get settingsSendSoundBody =>
      'Computers that show this screen also hear what it plays: music, videos, games. Only while the screen is shared, and never the microphone. Some apps block this and stay silent.';

  @override
  String get settingsSendSoundPermission =>
      'Android calls this permission \"record audio\" and files it under Microphone. Ferret only captures what the phone plays.';

  @override
  String get settingsSendSoundDenied =>
      'Android didn\'t allow it. To change that, open Ferret in Android\'s app settings, then Permissions → Microphone.';

  @override
  String get settingsSendSoundUnsupported =>
      'Sending sound takes Android 10 or newer.';

  @override
  String settingsUnsupported(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'This tablet',
        'other': 'This phone',
      },
    );
    return '$_temp0 can\'t capture its screen';
  }

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
  String permissionAsk(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return 'Ask to see $_temp0 screen';
  }

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
  String healthShareOff(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'Off on $_temp0';
  }

  @override
  String get healthShareOffHelp =>
      'Open Settings → To your computer and turn on Let my computers ask to see this screen.';

  @override
  String healthShareBlocked(String device) {
    return 'Off for $device';
  }

  @override
  String healthShareBlockedHelp(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return 'Turn on Ask to see $_temp0 screen for $device, further down this page.';
  }

  @override
  String healthSharing(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return 'Sees $_temp0 screen now';
  }

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
  String get targetCable => 'Cable';

  @override
  String get targetWireless => 'Wi-Fi debugging';

  @override
  String setupInstallToolBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Install Android\'s platform tools (they include adb) on $_temp0. This page moves on by itself.';
  }

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
  String setupDownloadFailed(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    String _temp1 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac\'s',
        'windows': 'this PC\'s',
        'other': '$_temp0\'s',
      },
    );
    return 'The download didn\'t finish. Check $_temp1 internet connection and try again.';
  }

  @override
  String get setupStartToolTitle => 'Start Android\'s helper tool';

  @override
  String setupStartToolBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Ferret isn\'t allowed to start adb on $_temp0. Open Android Studio, or run adb start-server in Terminal. This page moves on by itself.';
  }

  @override
  String setupPermissionTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Ferret needs your OK on $_temp0';
  }

  @override
  String setupPermissionBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    String _temp1 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac\'s',
        'windows': 'this PC\'s',
        'other': '$_temp0\'s',
      },
    );
    return 'Allow Ferret under Local Network in $_temp1 privacy settings.';
  }

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
  String plugInTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Plug $device into $_temp0';
  }

  @override
  String get plugInBody => 'You can click and type on it too.';

  @override
  String get buttonRotate => 'Rotate';

  @override
  String get buttonKeyboard => 'Keyboard';

  @override
  String get buttonScreenshot => 'Screenshot';

  @override
  String screenshotSaved(String folder) {
    return 'Saved to $folder';
  }

  @override
  String get screenshotFailed => 'The screenshot couldn\'t be saved.';

  @override
  String get showInFinder => 'Show in Finder';

  @override
  String get showInFolder => 'Show in folder';

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
  String get soundTitle => 'Sound';

  @override
  String get soundDetailHere => 'Here';

  @override
  String get soundDetailThere => 'On the phone';

  @override
  String get soundDetailNone => 'None';

  @override
  String soundHere(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'On $_temp0';
  }

  @override
  String soundThere(String device) {
    return 'On $device';
  }

  @override
  String get soundVolume => 'Volume';

  @override
  String soundMovesNote(String device) {
    return '$device goes quiet while its sound plays here. Changing it restarts the picture.';
  }

  @override
  String soundCopiesNote(String device) {
    return '$device keeps playing too: turn its volume down to hear it only here. Apps that block capture, like some video apps, stay silent.';
  }

  @override
  String soundNextTime(String device) {
    return '$device has to say yes again, so sound starts next time.';
  }

  @override
  String soundNotAllowed(String device) {
    return '$device isn\'t sending its sound. On the phone, open Ferret, then Settings → Screen, and turn on Send sound too.';
  }

  @override
  String soundUnsupportedCable(String device) {
    return '$device can\'t send its sound. That takes Android 11 or newer, and an unlocked screen when the picture starts.';
  }

  @override
  String soundUnsupportedWifi(String device) {
    return '$device can\'t send its sound. That takes Android 10 or newer and the latest Ferret on it.';
  }

  @override
  String soundFailed(String device) {
    return '$device couldn\'t capture its sound. Stop, then show the screen again.';
  }

  @override
  String get soundNoOutput =>
      'This computer couldn\'t play the sound. Check its sound output.';

  @override
  String get soundAirplay =>
      'Sound over AirPlay isn\'t here yet. It stays on the iPhone.';

  @override
  String get soundWaiting => 'Waiting for sound…';

  @override
  String get qualityGood => 'Good';

  @override
  String get qualitySlow => 'Slow';

  @override
  String get qualityPoor => 'Poor';

  @override
  String get pictureTitle => 'Picture';

  @override
  String pictureTooltip(String quality) {
    return 'Picture: $quality';
  }

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
  String basicPicture(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Basic picture on $_temp0 for now (about 10 a second).';
  }

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
  String stepPlug(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Plug the phone into $_temp0';
  }

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
  String setupPrivacy(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Once allowed, $_temp0 can see and control the phone without asking. Only do this with your own phone.';
  }

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
  String airplayListeningLeft(String time) {
    return 'Listening… $time';
  }

  @override
  String setupStepNumbered(int number, String step) {
    return '$number. $step';
  }

  @override
  String get airplayNote =>
      'View only. No sound. Beta: an iOS update can break it.';

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
  String airplayTimedOutTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Nobody picked $_temp0';
  }

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

  @override
  String get controlAsk => 'Control';

  @override
  String get controlAsking => 'Asking…';

  @override
  String noticeControlAsking(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'On $device, tap Once or Always to let $_temp0 click and type there.';
  }

  @override
  String noticeControlAllowed(String device) {
    return 'You can click and type on $device now.';
  }

  @override
  String noticeControlDenied(String device) {
    return '$device said no to control. You can still watch.';
  }

  @override
  String noticeControlTimedOut(String device) {
    return 'Nobody answered on $device. Click Control to ask again.';
  }

  @override
  String noticeControlStopped(String device) {
    return '$device stopped control. You can still watch.';
  }

  @override
  String viewOnlySetupBody(String device) {
    return 'To click and type over Wi-Fi, turn on Ferret control on $device: open Ferret there, then Settings → To your computer.';
  }

  @override
  String controlAskTitle(String computer, String phone) {
    return 'Let $computer control $phone while showing its screen?';
  }

  @override
  String controlAskCardTitle(String computer, String phone) {
    return 'Let $computer control $phone?';
  }

  @override
  String controlAskBody(String computer) {
    return 'While it shows this screen, $computer can tap, swipe and type here, until you stop it.';
  }

  @override
  String get controlAlways => 'Always';

  @override
  String get controlOnce => 'Once';

  @override
  String get controlNo => 'No';

  @override
  String controlledTitle(String computer) {
    return 'Being controlled by $computer';
  }

  @override
  String get controlledBody =>
      'It can tap and type here while it shows this screen.';

  @override
  String get controlStop => 'Stop control';

  @override
  String get controlStopSharing => 'Stop sharing';

  @override
  String get noticeControlChannel => 'Control from a computer';

  @override
  String get settingsControlTitle => 'Control from a computer';

  @override
  String get settingsControlPowerUps =>
      'A computer that shows this screen can tap and type here, through Power-ups. It asks you first.';

  @override
  String get settingsControlService =>
      'Ferret control is on. A computer that shows this screen can tap and type here after it asks you.';

  @override
  String get settingsControlOff =>
      'To let a computer that shows this screen tap and type here, turn on Ferret control in Android\'s Accessibility settings.';

  @override
  String get settingsControlTurnOn => 'Turn on Ferret control…';

  @override
  String get settingsControlTurnOnShort => 'Turn on control…';

  @override
  String get settingsControlOpen => 'Accessibility settings';

  @override
  String get settingsControlOpenShort => 'Open settings';

  @override
  String settingsControlAlwaysCount(int count, String here) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count computers control',
      one: '1 computer controls',
    );
    String _temp1 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return '$_temp0 $_temp1 without asking.';
  }

  @override
  String get settingsControlAskAgain => 'Ask every time';

  @override
  String get controlDisclosureTitle => 'Turn on Ferret control?';

  @override
  String controlDisclosureBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'Ferret control is an Android accessibility service. With it, a computer you paired can tap, swipe, press Back and Home, and type on $_temp0.\n\nIt acts only while you show this screen to that computer and said yes to control. A notice says so the whole time, with Stop.\n\nTo type, it reads the text field you type into. It reads nothing else, keeps nothing, and sends nothing anywhere.';
  }

  @override
  String get controlDisclosureSteps =>
      'Next, in Accessibility, tap Ferret control and turn it on.';

  @override
  String get controlDisclosureOpen => 'Open settings';

  @override
  String get notNow => 'Not now';

  @override
  String useCamera(String device) {
    return 'Use $device\'s camera';
  }

  @override
  String get useCameraShort => 'Use camera';

  @override
  String cameraWindowTitle(String device) {
    return '$device — Camera';
  }

  @override
  String get cameraSavePicture => 'Save a picture';

  @override
  String get cameraSwitch => 'Switch camera';

  @override
  String get cameraUseAgain => 'Use again';

  @override
  String get cameraPictureNote => '720p at 30 frames a second, like a webcam.';

  @override
  String cameraWaitingBody(String device) {
    return 'On $device, tap Once or Always to turn its camera on.';
  }

  @override
  String cameraWaitingNothing(String device) {
    return 'Nothing on $device? Open Ferret there.';
  }

  @override
  String cameraDeniedBody(String device) {
    return 'Someone tapped No on $device.';
  }

  @override
  String cameraBusyTitle(String device) {
    return '$device is busy';
  }

  @override
  String get cameraBusyBody =>
      'Its screen or its camera is already on for a device. Stop that one first.';

  @override
  String cameraUnsupportedTitle(String device) {
    return '$device can\'t share its camera';
  }

  @override
  String get cameraUnsupportedBody =>
      'Using a phone\'s camera needs an Android phone with the latest Ferret.';

  @override
  String cameraTurnedOffTitle(String device) {
    return 'Camera is off on $device';
  }

  @override
  String cameraTurnedOffBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'On $device: open Ferret → Settings → To your computer and turn on Let my computers ask to use this camera. Then open $_temp0 there and check that it may ask.';
  }

  @override
  String cameraCannotStartTitle(String device) {
    return '$device couldn\'t turn its camera on';
  }

  @override
  String cameraCannotStartBody(String device) {
    return 'On $device: open Ferret and allow the camera. Then ask again.';
  }

  @override
  String cameraStoppedHereBody(String device) {
    return '$device\'s camera is off.';
  }

  @override
  String cameraSystemEndedTitle(String device) {
    return '$device turned its camera off';
  }

  @override
  String cameraSystemEndedBody(String device) {
    return 'Android closed the camera, or another app took it. Use it again when $device is ready.';
  }

  @override
  String cameraFailedBody(String device) {
    return '$device couldn\'t start its camera.';
  }

  @override
  String cameraViewingTitle(String device) {
    return 'Using $device\'s camera';
  }

  @override
  String cameraAuditViewed(String device, String duration, String time) {
    return 'You used $device\'s camera for $duration at $time';
  }

  @override
  String cameraAuditShared(
    String device,
    String duration,
    String time,
    String here,
  ) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return '$device used $_temp0 camera for $duration at $time';
  }

  @override
  String cameraLeaveTitle(String device) {
    return 'Stop using $device\'s camera?';
  }

  @override
  String get cameraLeaveBody => 'Leaving this page turns the camera off.';

  @override
  String get cameraKeep => 'Keep it on';

  @override
  String cameraAskTitle(String computer) {
    return '$computer wants to use your camera';
  }

  @override
  String get cameraAskBody =>
      'It will see through the camera and hear the microphone, until you stop it.';

  @override
  String cameraOnTitle(String computer) {
    return 'Camera on for $computer';
  }

  @override
  String cameraOnBody(String time, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'It sees and hears through $_temp0. Since $time.';
  }

  @override
  String cameraOnBodySilent(String time, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return 'It sees through $_temp0 camera. The microphone is off. Since $time.';
  }

  @override
  String noticeCameraBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'It sees and hears through $_temp0';
  }

  @override
  String noticeCameraBodySilent(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return 'It sees through $_temp0 camera';
  }

  @override
  String get noticeCameraChannel => 'Camera for a computer';

  @override
  String get settingsCameraTitle => 'Camera for a computer';

  @override
  String get settingsCameraAllow => 'Let my computers ask to use this camera';

  @override
  String get settingsCameraAllowBody =>
      'You answer Once, Always or No. A notice with Stop stays up while the camera is on.';

  @override
  String settingsCameraAlwaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count computers use this camera without asking.',
      one: '1 computer uses this camera without asking.',
    );
    return '$_temp0';
  }

  @override
  String permissionCameraAsk(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet\'s',
        'other': 'this phone\'s',
      },
    );
    return 'Ask to use $_temp0 camera';
  }

  @override
  String get permissionCameraAskOff =>
      'Camera is off for every computer. Turn it on in Settings → To your computer.';

  @override
  String get cameraTitle => 'Camera';

  @override
  String displayUse(String device) {
    return 'Use $device as a display';
  }

  @override
  String displayStopUsing(String device) {
    return 'Stop using $device as a display';
  }

  @override
  String get displayUseShort => 'Use as display';

  @override
  String get displayStopShort => 'Stop display';

  @override
  String displayAskingTitle(String device) {
    return 'Asking $device to be a display…';
  }

  @override
  String displayAskingBody(String device) {
    return 'Someone on $device has to say yes there.';
  }

  @override
  String displayStartingTitle(String device) {
    return 'Making a display for $device…';
  }

  @override
  String displayExtendingTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return '$device is a display for $_temp0';
  }

  @override
  String displayExtendingDetail(String time) {
    return 'Since $time · Arrange it in System Settings → Displays';
  }

  @override
  String displayEnded(String device, String end) {
    String _temp0 = intl.Intl.selectLogic(
      end,
      {
        'declined': '$device said no to being a display',
        'timedOut': 'Nobody answered on $device',
        'busy': '$device is already another computer\'s display',
        'unsupported': '$device can\'t be a display yet. Update Ferret there.',
        'notConnected': '$device isn\'t connected',
        'noAnswer': '$device didn\'t answer',
        'cannotExtend': 'This Mac can\'t make an extra display. It needs macOS 12.3 or later.',
        'needsScreenRecording':
            'Allow Ferret in Screen Recording to use $device as a display',
        'stoppedHere': 'Stopped using $device as a display',
        'stoppedThere': '$device stopped being a display',
        'lostConnection': 'Lost $device, so its display went away',
        'systemEnded': 'macOS ended the display on $device',
        'other': 'The display on $device stopped working',
      },
    );
    return '$_temp0';
  }

  @override
  String get displayScreenRecordingBody =>
      'System Settings → Privacy & Security → Screen Recording. Turn on Ferret, then quit and open it again. Switch greyed out? On a work Mac, your IT team decides.';

  @override
  String get displayOpenSettings => 'Open Settings';

  @override
  String displayAllowTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'android': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '$device wants to use $_temp0 as a display';
  }

  @override
  String get displayAllowBody =>
      'Your mouse and keyboard will work on its desktop. Allow only if it\'s yours.';

  @override
  String get displayAllow => 'Allow';

  @override
  String displayShowingTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'This Mac',
        'windows': 'This PC',
        'android': 'This phone',
        'tablet': 'This tablet',
        'other': 'This computer',
      },
    );
    return '$_temp0 is $device\'s display';
  }

  @override
  String displayShowingDetail(String time) {
    return 'Since $time · Esc leaves full screen';
  }

  @override
  String displayWindowTitle(String device) {
    return '$device — Display';
  }

  @override
  String displayConnectingTitle(String device) {
    return 'Connecting to $device…';
  }

  @override
  String displayConnectingBody(String device) {
    return '$device is making a display the size of this screen.';
  }

  @override
  String displayBarTitle(String device) {
    return '$device\'s display';
  }

  @override
  String get displayEscHint => 'Esc leaves full screen';

  @override
  String displayViewEnded(String device, String end, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'android': 'this phone',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    String _temp1 = intl.Intl.selectLogic(
      end,
      {
        'stoppedOnPhone': '$device stopped using $_temp0 as a display',
        'stoppedHere': 'Stopped being $device\'s display',
        'lostConnection': 'Lost $device',
        'noAnswer': '$device didn\'t send its display',
        'denied': '$device took its offer back',
        'other': '$device\'s display stopped working',
      },
    );
    return '$_temp1';
  }

  @override
  String displayNoInput(String device) {
    return '$device can\'t take your clicks yet: allow Ferret in Accessibility there.';
  }

  @override
  String get displayAllowBodyTouch =>
      'Your fingers will work as its mouse. Allow only if it\'s yours.';

  @override
  String displayShowingSince(String time) {
    return 'Since $time';
  }

  @override
  String get displayTouchHint =>
      'Tap to click · Hold to right-click · Two fingers scroll';

  @override
  String displayHandleLabel(String device) {
    return 'Show the bar for $device\'s display';
  }

  @override
  String displayStopTitle(String device) {
    return 'Stop being $device\'s display?';
  }

  @override
  String displayStopBody(String device) {
    return 'Its windows on this screen go back to $device.';
  }

  @override
  String get beta => 'Beta';

  @override
  String get betaTooltip =>
      'Works in our tests, not yet on enough real devices';

  @override
  String inBeta(String text) {
    return '$text (beta)';
  }

  @override
  String displayingTitle(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'This tablet',
        'other': 'This phone',
      },
    );
    return '$_temp0 is $device\'s display';
  }

  @override
  String get displayingBody =>
      'Tap to see it again. It stops by itself after 10 minutes in the background.';
}
