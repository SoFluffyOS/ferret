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
  String get cardEmpty =>
      'Copy something here and paste it on your other devices.';

  @override
  String get cardOffline =>
      'Your devices are offline. Copies sync when one is back.';

  @override
  String get cardEmptyManual => 'Copy something, then tap Send clipboard.';

  @override
  String statusWithTime(String status, String time) {
    return '$status · $time';
  }

  @override
  String copiedFrom(String device) {
    return 'Copied from $device';
  }

  @override
  String waitingToCopyFrom(String device) {
    return 'From $device, not on your clipboard yet';
  }

  @override
  String sentTo(String devices) {
    return 'Sent to $devices';
  }

  @override
  String get sentNowhere => 'Copied here, no device connected';

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
  String get timeJustNow => 'just now';

  @override
  String timeMinutes(int count) {
    return '$count min ago';
  }

  @override
  String timeHours(int count) {
    return '$count h ago';
  }

  @override
  String timeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
    );
    return '$_temp0';
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
  String get resultSent => 'Sent.';

  @override
  String get resultNothingToSend =>
      'The clipboard is empty, or holds something other than text or an image.';

  @override
  String get resultDuplicate => 'Already sent.';

  @override
  String get resultSensitive =>
      'Not sent: the app you copied from marked it as private. Turn on Include passwords in Settings to send these.';

  @override
  String get resultImagesOff =>
      'Not sent: images are off. Turn on Images in Settings to send them.';

  @override
  String get resultTooLarge => 'Not sent: it\'s bigger than the size limit.';

  @override
  String get resultNoDevices =>
      'No device is connected. Open Ferret on your other device, on the same Wi-Fi.';

  @override
  String get resultFailed =>
      'Couldn\'t reach your devices. Check they\'re on the same Wi-Fi, then try again.';

  @override
  String get settingsAutoSend => 'Send automatically';

  @override
  String get settingsAutoSendBody =>
      'Send what you copy here to your connected devices.';

  @override
  String get settingsAutoSendBodyManual =>
      'This phone only allows it for copies made inside Ferret. Use Send clipboard for the rest.';

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
      'Needs Shizuku or root. Set one up under Power-ups.';

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
    return 'Off by default: copied passwords are skipped. On, they sync and are wiped after $minutes min.';
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
}
