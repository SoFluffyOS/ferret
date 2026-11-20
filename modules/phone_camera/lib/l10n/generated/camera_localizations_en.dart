// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'camera_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CameraLocalizationsEn extends CameraLocalizations {
  CameraLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Camera';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get scanDocument => 'Scan a document';

  @override
  String askPhotoTitle(String device) {
    return '$device wants a photo';
  }

  @override
  String askDocumentTitle(String device) {
    return '$device wants a document scan';
  }

  @override
  String get askBody => 'Nothing is taken until you press the shutter.';

  @override
  String get askCapturing => 'The camera is open.';

  @override
  String get askTakePhoto => 'Take photo';

  @override
  String get askScan => 'Scan';

  @override
  String get askNotNow => 'Not now';

  @override
  String noticeBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'Tap to answer on $_temp0.';
  }

  @override
  String activityWaiting(String device) {
    return 'Waiting for a photo from $device';
  }

  @override
  String activityWaitingScan(String device) {
    return 'Waiting for a scan from $device';
  }

  @override
  String activityWaitingDetail(String device) {
    return 'Take it on $device.';
  }

  @override
  String activityReceiving(String device) {
    return 'Getting the picture from $device';
  }

  @override
  String activityPhoto(String device) {
    return 'Photo from $device';
  }

  @override
  String activityScan(String device) {
    return 'Scan from $device';
  }

  @override
  String get activityOnClipboard => 'On your clipboard';

  @override
  String get activityInFolder => 'In your receive folder';

  @override
  String get copy => 'Copy';

  @override
  String get cancel => 'Cancel';

  @override
  String get tryAgain => 'Try again';

  @override
  String endDeclined(String device) {
    return '$device said not now';
  }

  @override
  String endCancelled(String device) {
    return 'No picture taken on $device';
  }

  @override
  String endUnsupported(String device) {
    return '$device can\'t take that';
  }

  @override
  String get endUnsupportedDetail =>
      'It has no camera Ferret can open, or no document scanner.';

  @override
  String endNoPermission(String device) {
    return 'No camera access on $device';
  }

  @override
  String get endNoPermissionDetail =>
      'Allow the camera for Ferret in the phone\'s settings.';

  @override
  String endBusy(String device) {
    return 'The camera on $device is already open';
  }

  @override
  String endOffline(String device) {
    return '$device isn\'t connected';
  }

  @override
  String endFailed(String device) {
    return 'The picture from $device didn\'t arrive';
  }

  @override
  String endExpired(String device) {
    return 'Nobody took the photo on $device';
  }
}
