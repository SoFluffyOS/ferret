// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'clipboard_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ClipboardLocalizationsEn extends ClipboardLocalizations {
  ClipboardLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Clipboard';

  @override
  String sentTo(String devices) {
    return 'Sent to $devices';
  }

  @override
  String get sentNowhere => 'Copied here, no device connected';

  @override
  String get sentWaiting => 'Waiting for a device to connect';

  @override
  String sentWhenBack(String devices) {
    return 'Sent to $devices when it came back';
  }

  @override
  String get skippedSensitive => 'Not synced: marked as private';

  @override
  String get skippedImagesOff => 'Not synced: images are off';

  @override
  String get skippedTooLarge => 'Not synced: too large';

  @override
  String writeFailed(String device) {
    return 'From $device, not on this clipboard yet. Tap Copy.';
  }

  @override
  String activityCopiedOn(String device) {
    return 'Copied on $device';
  }

  @override
  String get activityNotSent => 'Clipboard not sent';

  @override
  String activityQuote(String text) {
    return '“$text”';
  }

  @override
  String get imageLabel => 'Image';

  @override
  String get privateCleared => 'Private item, cleared from memory';

  @override
  String get privateHidden => 'Private item';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get sendClipboard => 'Send clipboard';

  @override
  String get offerBackgroundSend =>
      'Send what you copy on its own, even in the background.';

  @override
  String get offerTurnOn => 'Turn on';

  @override
  String get offerTile =>
      'Send your clipboard in one tap from the Ferret tile in Quick Settings.';

  @override
  String get offerAddTile => 'Add tile';

  @override
  String get resultSent => 'Sent.';

  @override
  String get resultNothingToSend =>
      'The clipboard is empty, or holds something other than text or an image.';

  @override
  String get resultDuplicate => 'Already sent.';

  @override
  String get resultSensitive =>
      'Not sent: the app you copied from marked it as private. Turn on Include passwords in Settings → Clipboard to send these.';

  @override
  String get resultImagesOff =>
      'Not sent: images are off. Turn on Images in Settings → Clipboard to send them.';

  @override
  String get resultTooLarge => 'Not sent: it\'s bigger than the size limit.';

  @override
  String get resultNoDevices =>
      'No device is connected. Open Ferret on your other device, on the same Wi-Fi.';

  @override
  String get resultFailed =>
      'Couldn\'t reach your devices. Check they\'re on the same Wi-Fi, then try again.';

  @override
  String get summarySyncs => 'Syncs by itself';

  @override
  String get summarySends => 'Sends by itself';

  @override
  String get summaryByHand => 'Send by hand';

  @override
  String get healthSyncs => 'Syncs by itself';

  @override
  String get healthByHand => 'Send by hand';

  @override
  String healthOnlyHereSends(String name) {
    return 'Sends by itself. $name sends by hand.';
  }

  @override
  String healthOnlyTheySend(String name) {
    return '$name sends by itself. Send by hand from here.';
  }

  @override
  String healthUnsupported(String name) {
    return 'Needs a Ferret update on $name';
  }

  @override
  String get settingsBackgroundSendLost =>
      'Background sending stopped: Shizuku or root is no longer on. Set it up again in Settings → Control → Power-ups.';

  @override
  String get settingsAutoSend => 'Send automatically';

  @override
  String get settingsAutoSendBody =>
      'Send what you copy here to your connected devices.';

  @override
  String settingsAutoSendBodyManual(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'This tablet',
        'other': 'This phone',
      },
    );
    return '$_temp0 only allows it for copies made inside Ferret. Use Send clipboard for the rest.';
  }

  @override
  String get settingsBackgroundSend => 'Send automatically in the background';

  @override
  String get settingsBackgroundSendBody =>
      'Send text you copy in any app, also while Ferret is closed. Uses your power-up (Shizuku or root). Images still need Send clipboard.';

  @override
  String get settingsWhyManual => 'Why Send clipboard?';

  @override
  String get settingsWhyManualAndroid =>
      'Android doesn\'t let apps read your clipboard in the background. Copy, then tap Send clipboard in Ferret, in its notification or in the Quick Settings tile.';

  @override
  String get settingsWhyManualIos =>
      'iPhone only lets apps read your clipboard when you ask. Copy, then tap Send clipboard.';

  @override
  String get settingsBackgroundSendLocked =>
      'Needs Shizuku or root. Set one up in Settings → Control → Power-ups.';

  @override
  String get settingsAutoReceive => 'Receive automatically';

  @override
  String get settingsAutoReceiveBody =>
      'Put what your devices send straight on this clipboard. When off, tap Copy next to what arrived.';

  @override
  String get settingsImages => 'Images';

  @override
  String settingsImagesBody(int megabytes) {
    return 'Sync copied images up to $megabytes MB.';
  }

  @override
  String get settingsSensitive => 'Include passwords';

  @override
  String settingsSensitiveBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
    );
    return 'Off by default: copied passwords are skipped. On, they sync and are wiped after $_temp0.';
  }

  @override
  String settingsHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items in history, in memory only.',
      one: '1 item in history, in memory only.',
      zero: 'History is empty. It stays in memory, never on disk.',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearHistory => 'Clear history';

  @override
  String get settingsWhyManualWayland =>
      'On Wayland, only the window in front hears about a new copy. GNOME has no way around that, so Ferret sends what you copied once its window is in front again, or when you pick Send clipboard on a device or in the tray. On KDE Plasma and Sway, install wl-clipboard and Ferret watches by itself.';

  @override
  String get settingsAutoSendBodyWayland =>
      'On this desktop, copies go out while Ferret\'s window is in front. Use Send clipboard for the rest.';

  @override
  String get recentClips => 'Recent clips';

  @override
  String get recentClipsMenu => 'Recent clips…';

  @override
  String get recentClipsEmpty =>
      'Nothing copied yet. What you copy here or on your devices shows up here.';

  @override
  String get recentClipsNote =>
      'The last 20, kept in memory until Ferret quits. Private items never show up here.';

  @override
  String recentClipsKeys(String keys) {
    return 'Open this from any app with $keys.';
  }

  @override
  String recentFrom(String device) {
    return 'From $device';
  }

  @override
  String get recentCopiedHere => 'Copied here';

  @override
  String get recentHidden =>
      'Previews from this device are hidden here. Copy still works.';

  @override
  String get recentClipsDrag => 'Drag one into any app to drop it there.';
}
