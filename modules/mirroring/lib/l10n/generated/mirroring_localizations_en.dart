// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'mirroring_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class MirroringLocalizationsEn extends MirroringLocalizations {
  MirroringLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Screen mirroring';

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
    return 'Android asks whether to share the screen. Tap Start on $device. If the phone shows nothing, open the notice from Ferret there.';
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
  String get screenOffBody => 'Wake the phone to see it again.';

  @override
  String endDeniedTitle(String device) {
    return '$device said no';
  }

  @override
  String get endDeniedBody =>
      'Someone tapped Cancel on the phone\'s prompt. You can ask again in half a minute.';

  @override
  String endTimedOutTitle(String device) {
    return 'Nobody answered on $device';
  }

  @override
  String get endTimedOutBody =>
      'The question stays on the phone for a minute. Wake the phone, then try again.';

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
      'Screen mirroring needs an Android phone with Ferret.';

  @override
  String endTurnedOffTitle(String device) {
    return 'Screen mirroring is off on $device';
  }

  @override
  String get endTurnedOffBody =>
      'Turn it on in Ferret on the phone: Settings, then Screen mirroring.';

  @override
  String endCannotAskTitle(String device) {
    return '$device couldn\'t show the question';
  }

  @override
  String get endCannotAskBody =>
      'Open Ferret on the phone, or allow its notifications, then try again.';

  @override
  String endVersionTitle(String device) {
    return '$device needs a newer Ferret';
  }

  @override
  String get endVersionBody => 'Update Ferret on the phone, then try again.';

  @override
  String endNoCodecTitle(String device) {
    return '$device can\'t send a picture this computer can show';
  }

  @override
  String get endNoCodecBody => 'Update Ferret on both devices, then try again.';

  @override
  String endNotConnectedTitle(String device) {
    return '$device isn\'t connected';
  }

  @override
  String get endNotConnectedBody =>
      'Open Ferret on the phone and check both devices are on the same Wi-Fi.';

  @override
  String endNoAnswerTitle(String device) {
    return '$device didn\'t answer';
  }

  @override
  String get endNoAnswerBody =>
      'Check that Ferret is running on the phone, then try again.';

  @override
  String get endStoppedHereTitle => 'You stopped mirroring';

  @override
  String endStoppedHereBody(String device) {
    return '$device no longer shares its screen.';
  }

  @override
  String endStoppedOnPhoneTitle(String device) {
    return 'Stopped on $device';
  }

  @override
  String get endStoppedOnPhoneBody => 'Someone tapped Stop on the phone.';

  @override
  String endSystemEndedTitle(String device) {
    return '$device stopped sharing';
  }

  @override
  String get endSystemEndedBody =>
      'Android ends screen sharing when the phone locks, or when its owner stops it from the status bar.';

  @override
  String endLostConnectionTitle(String device) {
    return 'Lost the connection to $device';
  }

  @override
  String get endLostConnectionBody =>
      'Ferret reconnects on its own. Try again once the phone is back.';

  @override
  String get endFailedTitle => 'Mirroring stopped working';

  @override
  String endFailedBody(String device) {
    return 'Capturing the screen failed on $device. Try again.';
  }

  @override
  String get endDecoderFailedTitle =>
      'This computer couldn\'t show the picture';

  @override
  String get endDecoderFailedBody =>
      'Decoding the video failed here. Try again.';

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
  String get viewingWaitingBody => 'Answer the prompt on the phone.';

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
    return '$device viewed your screen for $duration at $time';
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
  String get healthViewing => 'Showing its screen here';

  @override
  String healthTurnedOff(String device) {
    return 'Screen mirroring is off on $device';
  }

  @override
  String healthUnsupported(String device) {
    return '$device can\'t share its screen';
  }

  @override
  String healthCannotAsk(String device) {
    return '$device couldn\'t show the question. Open Ferret on it.';
  }

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
      'Found by the experimental ways. No Ferret needed on the other device.';

  @override
  String get targetCable => 'Plugged in with a cable';

  @override
  String get targetWireless => 'On your network';

  @override
  String get show => 'Show';

  @override
  String get checkAgain => 'Check again';

  @override
  String get setupInstallToolTitle =>
      'This computer needs a small helper first';

  @override
  String get setupInstallToolBody =>
      'How to: install Android\'s platform tools (they include adb) on this computer, then try again.';

  @override
  String get setupEnableDebuggingTitle =>
      'The phone needs one setting turned on';

  @override
  String get setupEnableDebuggingBody =>
      'How to: on the phone, open Settings, then About phone, and tap Build number seven times. Then turn on USB debugging in Developer options.';

  @override
  String get setupAuthorizeTitle => 'Allow this computer on the phone';

  @override
  String get setupAuthorizeBody =>
      'How to: look at the phone and tap Allow on the question it shows, then try again.';

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
}
