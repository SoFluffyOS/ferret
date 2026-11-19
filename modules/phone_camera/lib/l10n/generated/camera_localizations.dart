import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'camera_localizations_en.dart';
import 'camera_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CameraLocalizations
/// returned by `CameraLocalizations.of(context)`.
///
/// Applications need to include `CameraLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/camera_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CameraLocalizations.localizationsDelegates,
///   supportedLocales: CameraLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the CameraLocalizations.supportedLocales
/// property.
abstract class CameraLocalizations {
  CameraLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CameraLocalizations of(BuildContext context) {
    return Localizations.of<CameraLocalizations>(context, CameraLocalizations)!;
  }

  static const LocalizationsDelegate<CameraLocalizations> delegate =
      _CameraLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// The feature's name.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get title;

  /// Button on a phone's page on a computer: asks the phone to take a photo for this computer.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// Button on an iPhone's page on a computer: asks it to scan a document for this computer.
  ///
  /// In en, this message translates to:
  /// **'Scan a document'**
  String get scanDocument;

  /// Card and notice on a phone when a computer asks for a photo.
  ///
  /// In en, this message translates to:
  /// **'{device} wants a photo'**
  String askPhotoTitle(String device);

  /// No description provided for @askDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} wants a document scan'**
  String askDocumentTitle(String device);

  /// No description provided for @askBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is taken until you press the shutter.'**
  String get askBody;

  /// No description provided for @askCapturing.
  ///
  /// In en, this message translates to:
  /// **'The camera is open.'**
  String get askCapturing;

  /// No description provided for @askTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get askTakePhoto;

  /// No description provided for @askScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get askScan;

  /// No description provided for @askNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get askNotNow;

  /// No description provided for @noticeBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to answer on this phone.'**
  String get noticeBody;

  /// No description provided for @activityWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a photo from {device}'**
  String activityWaiting(String device);

  /// No description provided for @activityWaitingScan.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a scan from {device}'**
  String activityWaitingScan(String device);

  /// No description provided for @activityWaitingDetail.
  ///
  /// In en, this message translates to:
  /// **'Take it on {device}.'**
  String activityWaitingDetail(String device);

  /// No description provided for @activityReceiving.
  ///
  /// In en, this message translates to:
  /// **'Getting the picture from {device}'**
  String activityReceiving(String device);

  /// Activity line on a computer once the photo arrived.
  ///
  /// In en, this message translates to:
  /// **'Photo from {device}'**
  String activityPhoto(String device);

  /// No description provided for @activityScan.
  ///
  /// In en, this message translates to:
  /// **'Scan from {device}'**
  String activityScan(String device);

  /// No description provided for @activityOnClipboard.
  ///
  /// In en, this message translates to:
  /// **'On your clipboard'**
  String get activityOnClipboard;

  /// No description provided for @activityInFolder.
  ///
  /// In en, this message translates to:
  /// **'In your receive folder'**
  String get activityInFolder;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @endDeclined.
  ///
  /// In en, this message translates to:
  /// **'{device} said not now'**
  String endDeclined(String device);

  /// No description provided for @endCancelled.
  ///
  /// In en, this message translates to:
  /// **'No picture taken on {device}'**
  String endCancelled(String device);

  /// No description provided for @endUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t take that'**
  String endUnsupported(String device);

  /// No description provided for @endUnsupportedDetail.
  ///
  /// In en, this message translates to:
  /// **'It has no camera Ferret can open, or no document scanner.'**
  String get endUnsupportedDetail;

  /// No description provided for @endNoPermission.
  ///
  /// In en, this message translates to:
  /// **'No camera access on {device}'**
  String endNoPermission(String device);

  /// No description provided for @endNoPermissionDetail.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera for Ferret in the phone\'s settings.'**
  String get endNoPermissionDetail;

  /// No description provided for @endBusy.
  ///
  /// In en, this message translates to:
  /// **'The camera on {device} is already open'**
  String endBusy(String device);

  /// No description provided for @endOffline.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t connected'**
  String endOffline(String device);

  /// No description provided for @endFailed.
  ///
  /// In en, this message translates to:
  /// **'The picture from {device} didn\'t arrive'**
  String endFailed(String device);

  /// No description provided for @endExpired.
  ///
  /// In en, this message translates to:
  /// **'Nobody took the photo on {device}'**
  String endExpired(String device);
}

class _CameraLocalizationsDelegate
    extends LocalizationsDelegate<CameraLocalizations> {
  const _CameraLocalizationsDelegate();

  @override
  Future<CameraLocalizations> load(Locale locale) {
    return SynchronousFuture<CameraLocalizations>(
      lookupCameraLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_CameraLocalizationsDelegate old) => false;
}

CameraLocalizations lookupCameraLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return CameraLocalizationsEn();
    case 'vi':
      return CameraLocalizationsVi();
  }

  throw FlutterError(
    'CameraLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
