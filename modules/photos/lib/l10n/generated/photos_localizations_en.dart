// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'photos_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PhotosLocalizationsEn extends PhotosLocalizations {
  PhotosLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Photos';

  @override
  String get back => 'Back';

  @override
  String get autoScreenshots => 'New screenshots arrive by themselves';

  @override
  String autoScreenshotsBody(String device) {
    return 'Each screenshot you take on $device lands here while Ferret runs on both.';
  }

  @override
  String get select => 'Select';

  @override
  String get cancel => 'Cancel';

  @override
  String saveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $count photos',
      one: 'Save 1 photo',
    );
    return '$_temp0';
  }

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving…';

  @override
  String get saved => 'Saved to your receive folder.';

  @override
  String get saveFailed => 'Couldn\'t save it. Try again.';

  @override
  String limited(String device) {
    return '$device shares only the photos you picked.';
  }

  @override
  String get allowMore => 'Allow more photos';

  @override
  String loading(String device) {
    return 'Loading photos from $device…';
  }

  @override
  String offline(String device) {
    return '$device is offline. Its photos show here once it\'s back.';
  }

  @override
  String unsupported(String device) {
    return '$device needs a newer Ferret to share photos.';
  }

  @override
  String failed(String device) {
    return '$device didn\'t answer.';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String notAllowedTitle(String device) {
    return '$device doesn\'t share its photos here yet';
  }

  @override
  String notAllowedBody(String device) {
    return 'Your photos stay on the phone until you allow it. On $device, open this computer and turn on Photos under What it can use.';
  }

  @override
  String noPermissionTitle(String device) {
    return 'Ferret on $device can\'t see photos yet';
  }

  @override
  String noPermissionBody(String device) {
    return 'The phone hasn\'t given Ferret photo access. Allow it on $device.';
  }

  @override
  String askOnDevice(String device) {
    return 'Ask on $device';
  }

  @override
  String askedOnDevice(String device) {
    return 'A notice is waiting on $device.';
  }

  @override
  String unavailableTitle(String device) {
    return 'Open Ferret on $device to see photos';
  }

  @override
  String get unavailableBody =>
      'An iPhone shares photos only while Ferret is open on it.';

  @override
  String empty(String device) {
    return 'No photos on $device yet.';
  }

  @override
  String hidden(String device) {
    return 'Photos from $device are hidden on this computer right now.';
  }

  @override
  String kindPhoto(String date) {
    return 'Photo, $date';
  }

  @override
  String kindScreenshot(String date) {
    return 'Screenshot, $date';
  }

  @override
  String kindVideo(String date) {
    return 'Video, $date';
  }

  @override
  String activitySaving(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saving $count photos from $device',
      one: 'Saving a photo from $device',
    );
    return '$_temp0';
  }

  @override
  String activitySaved(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $count photos from $device',
      one: 'Saved a photo from $device',
    );
    return '$_temp0';
  }

  @override
  String activityScreenshot(String device) {
    return 'Screenshot from $device';
  }

  @override
  String activityFailed(String device) {
    return 'Couldn\'t save photos from $device';
  }

  @override
  String get activityInFolder => 'In your receive folder';

  @override
  String failOffline(String device) {
    return '$device went offline.';
  }

  @override
  String failNotAllowed(String device) {
    return '$device doesn\'t share photos with this computer.';
  }

  @override
  String failNoPermission(String device) {
    return 'Ferret on $device can\'t read photos.';
  }

  @override
  String failMissing(String device) {
    return 'Those photos aren\'t on $device any more.';
  }

  @override
  String get failOther => 'The transfer stopped. Try again.';

  @override
  String permissionLabel(String device) {
    return 'Let $device see your photos';
  }

  @override
  String permissionDetail(String device) {
    return 'Recent photos and screenshots, while Ferret runs. $device can look and save, never delete.';
  }

  @override
  String get permissionDetailLimited =>
      'Ferret sees only the photos you picked. Change it in Settings, Photos.';

  @override
  String get permissionDetailDenied =>
      'Photo access is off for Ferret. Turn it on in Settings, Photos.';

  @override
  String noticeAskTitle(String device) {
    return '$device wants to see your photos';
  }

  @override
  String get noticeAskBody => 'Tap to choose what it can see.';

  @override
  String get settingsFull => 'Ferret can see all your photos.';

  @override
  String get settingsLimited => 'Ferret sees only the photos you picked.';

  @override
  String get settingsDenied => 'Photo access is off for Ferret.';

  @override
  String get settingsNotAsked =>
      'Ferret asks for photo access when you share photos with a computer.';

  @override
  String get settingsUnavailable => 'Photos can\'t be read right now.';

  @override
  String get allowPhotos => 'Allow photos';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get settingsPerDevice =>
      'Choose which computers see your photos on each computer\'s page, under What it can use. Nothing is ever deleted from here.';

  @override
  String settingsSharing(String devices) {
    return 'Shared with: $devices';
  }

  @override
  String get settingsSharingNone => 'Not shared with any computer.';
}
