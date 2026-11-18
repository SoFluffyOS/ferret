// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'find_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class FindLocalizationsEn extends FindLocalizations {
  FindLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Find my device';

  @override
  String get ring => 'Ring';

  @override
  String get foundIt => 'Found it';

  @override
  String get stop => 'Stop';

  @override
  String get ringAgain => 'Ring again';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get done => 'Done';

  @override
  String get ringingTitle => 'Ferret is ringing';

  @override
  String ringingBody(String name) {
    return '$name is looking for this device.';
  }

  @override
  String get ringingMuted => 'This device is on silent, so it only vibrates.';

  @override
  String get ringingHere => 'This device is ringing';

  @override
  String findDevice(String name) {
    return 'Find $name';
  }

  @override
  String outgoingRequesting(String name) {
    return 'Asking $name to ring…';
  }

  @override
  String outgoingRinging(String name) {
    return 'Ringing $name…';
  }

  @override
  String get outgoingRingingDetail =>
      'It rings for up to 2 minutes, or until someone taps Found it.';

  @override
  String outgoingRingingMuted(String name) {
    return '$name is on silent there, so it only vibrates. Turn on Ring on silent in Ferret on $name to hear it.';
  }

  @override
  String outgoingFound(String name) {
    return '$name was found.';
  }

  @override
  String outgoingTimedOut(String name) {
    return '$name stopped ringing on its own.';
  }

  @override
  String outgoingStoppedHere(String name) {
    return 'Stopped ringing $name.';
  }

  @override
  String outgoingStoppedElsewhere(String name) {
    return '$name was stopped from another device.';
  }

  @override
  String outgoingNoSound(String name) {
    return '$name couldn\'t play a sound.';
  }

  @override
  String get outgoingNoSoundDetail =>
      'Check that its sound works, then ring again.';

  @override
  String outgoingUnreachable(String name) {
    return '$name didn\'t answer.';
  }

  @override
  String get outgoingUnreachableDetail =>
      'Make sure it\'s on and on the same Wi-Fi, then ring again.';

  @override
  String outgoingNotSupported(String name) {
    return '$name can\'t ring yet.';
  }

  @override
  String outgoingNotSupportedDetail(String name) {
    return 'Update Ferret on $name, then ring again.';
  }

  @override
  String outgoingLostConnection(String name) {
    return 'Lost the connection to $name.';
  }

  @override
  String get outgoingLostConnectionDetail =>
      'It keeps ringing for up to 2 minutes, or until someone taps Found it there.';

  @override
  String get settingsRingOnSilent => 'Ring on silent';

  @override
  String get settingsRingOnSilentAndroid =>
      'Rings at full volume, even on silent or Do Not Disturb. The volume goes back after.';

  @override
  String get settingsRingOnSilentMac =>
      'Turns the volume up and unmutes while ringing, then puts it back.';

  @override
  String get settingsFlashTorch => 'Flash the torch';

  @override
  String get settingsFlashTorchBody =>
      'Blinks the flashlight while ringing, so you spot it in the dark.';

  @override
  String get settingsDndOn => 'Rings through Do Not Disturb.';

  @override
  String get settingsDndOff => 'Do Not Disturb access is off';

  @override
  String get settingsDndHowTo =>
      'Without it, this phone rings on silent but stays quiet in Do Not Disturb. Tap Allow, find Ferret in the list and turn it on.';

  @override
  String get settingsDndStillOff =>
      'Still off. Find Ferret in the list, turn it on, then come back.';

  @override
  String get settingsAllow => 'Allow in Settings';

  @override
  String get settingsOpenFailed =>
      'Couldn\'t open Settings. Open Settings, then Notifications, then Do Not Disturb access, and turn Ferret on.';

  @override
  String get settingsFullScreenOff =>
      'The ringing screen can\'t show over the lock screen';

  @override
  String get settingsFullScreenHowTo =>
      'You still hear it and get a notification. Allow full-screen notifications to see Found it right away.';

  @override
  String get settingsLimitIos =>
      'iPhone rings, even on silent, only while Ferret is open. iOS stops apps soon after they leave the screen.';

  @override
  String get settingsLimitDesktop =>
      'Rings at the current volume. Keep the sound on to hear it.';

  @override
  String get settingsLimitNoPlayer =>
      'No sound player found, so this computer can\'t ring. Install pw-play, paplay or aplay.';

  @override
  String get settingsTestRing => 'Test ring';

  @override
  String get settingsTestRingBody => 'Rings this device for 5 seconds.';

  @override
  String healthLoud(String name) {
    return '$name rings even on silent.';
  }

  @override
  String healthFollowsSilent(String name) {
    return '$name rings, but stays quiet on silent.';
  }

  @override
  String healthNeedsAppOpen(String name) {
    return '$name rings only while Ferret is open on it.';
  }

  @override
  String healthNeedsPermission(String name) {
    return '$name won\'t ring in Do Not Disturb. Open Ferret on $name and allow Do Not Disturb access.';
  }

  @override
  String healthNotAnswering(String name) {
    return '$name didn\'t answer, so ringing it may not work right now.';
  }

  @override
  String healthNoSound(String name) {
    return '$name couldn\'t play a sound last time.';
  }

  @override
  String healthUnsupported(String name) {
    return 'Ferret on $name can\'t ring. Update it there.';
  }
}
