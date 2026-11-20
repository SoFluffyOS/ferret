import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'photos_localizations_en.dart';
import 'photos_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PhotosLocalizations
/// returned by `PhotosLocalizations.of(context)`.
///
/// Applications need to include `PhotosLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/photos_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PhotosLocalizations.localizationsDelegates,
///   supportedLocales: PhotosLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the PhotosLocalizations.supportedLocales
/// property.
abstract class PhotosLocalizations {
  PhotosLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PhotosLocalizations of(BuildContext context) {
    return Localizations.of<PhotosLocalizations>(context, PhotosLocalizations)!;
  }

  static const LocalizationsDelegate<PhotosLocalizations> delegate =
      _PhotosLocalizationsDelegate();

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

  /// The feature's name and the device section's title.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get title;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Switch on a phone's Photos page on a computer. Off by default.
  ///
  /// In en, this message translates to:
  /// **'New screenshots arrive by themselves'**
  String get autoScreenshots;

  /// No description provided for @autoScreenshotsBody.
  ///
  /// In en, this message translates to:
  /// **'Each screenshot you take on {device} lands here while Ferret runs on both.'**
  String autoScreenshotsBody(String device);

  /// Heading over the grid of a phone's photos, newest first.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button that saves the selected photos into the receive folder.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save 1 photo} other{Save {count} photos}}'**
  String saveCount(int count);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// Button on a saved photo or video: opens it in its app.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openSaved;

  /// No description provided for @revealSaved.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get revealSaved;

  /// No description provided for @revealSavedFinder.
  ///
  /// In en, this message translates to:
  /// **'Show in Finder'**
  String get revealSavedFinder;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your receive folder.'**
  String get saved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save it. Try again.'**
  String get saveFailed;

  /// No description provided for @limited.
  ///
  /// In en, this message translates to:
  /// **'{device} shares only the photos you picked.'**
  String limited(String device);

  /// No description provided for @allowMore.
  ///
  /// In en, this message translates to:
  /// **'Allow more photos'**
  String get allowMore;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading photos from {device}…'**
  String loading(String device);

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'{device} is offline. Its photos show here once it\'s back.'**
  String offline(String device);

  /// No description provided for @unsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} needs a newer Ferret to share photos.'**
  String unsupported(String device);

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer.'**
  String failed(String device);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @notAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} doesn\'t share its photos here yet'**
  String notAllowedTitle(String device);

  /// No description provided for @notAllowedBody.
  ///
  /// In en, this message translates to:
  /// **'Your photos stay on the phone until you allow it. On {device}, open {here, select, macOS{this Mac} windows{this PC} other{this computer}} in Ferret and turn on the photos switch under What it can use.'**
  String notAllowedBody(String device, String here);

  /// No description provided for @noPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Ferret on {device} can\'t see photos yet'**
  String noPermissionTitle(String device);

  /// No description provided for @noPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'The phone hasn\'t given Ferret photo access. Allow it on {device}.'**
  String noPermissionBody(String device);

  /// Sends a notice to the phone asking its owner to share photos.
  ///
  /// In en, this message translates to:
  /// **'Ask on {device}'**
  String askOnDevice(String device);

  /// Short button for askOnDevice; the full sentence with the device name is its tooltip
  ///
  /// In en, this message translates to:
  /// **'Ask for access'**
  String get askShort;

  /// No description provided for @askedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'A notice is waiting on {device}.'**
  String askedOnDevice(String device);

  /// No description provided for @unavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret on {device} to see photos'**
  String unavailableTitle(String device);

  /// No description provided for @unavailableBody.
  ///
  /// In en, this message translates to:
  /// **'An iPhone shares photos only while Ferret is open on it.'**
  String get unavailableBody;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'No photos on {device} yet.'**
  String empty(String device);

  /// Shown while previews from that phone are off here, the screen is locked, or another account is in front.
  ///
  /// In en, this message translates to:
  /// **'Photos from {device} are hidden on {here, select, macOS{this Mac} windows{this PC} other{this computer}} right now.'**
  String hidden(String device, String here);

  /// Read by screen readers for a tile.
  ///
  /// In en, this message translates to:
  /// **'Photo, {date}'**
  String kindPhoto(String date);

  /// No description provided for @kindScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot, {date}'**
  String kindScreenshot(String date);

  /// No description provided for @kindVideo.
  ///
  /// In en, this message translates to:
  /// **'Video, {date}'**
  String kindVideo(String date);

  /// No description provided for @activitySaving.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saving a photo from {device}} other{Saving {count} photos from {device}}}'**
  String activitySaving(int count, String device);

  /// No description provided for @activitySaved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saved a photo from {device}} other{Saved {count} photos from {device}}}'**
  String activitySaved(int count, String device);

  /// No description provided for @activityScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot from {device}'**
  String activityScreenshot(String device);

  /// No description provided for @activityFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save photos from {device}'**
  String activityFailed(String device);

  /// No description provided for @activityInFolder.
  ///
  /// In en, this message translates to:
  /// **'In your receive folder'**
  String get activityInFolder;

  /// No description provided for @failOffline.
  ///
  /// In en, this message translates to:
  /// **'{device} went offline.'**
  String failOffline(String device);

  /// No description provided for @failNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'{device} doesn\'t share photos with {here, select, macOS{this Mac} windows{this PC} other{this computer}}.'**
  String failNotAllowed(String device, String here);

  /// No description provided for @failNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Ferret on {device} can\'t read photos.'**
  String failNoPermission(String device);

  /// No description provided for @failMissing.
  ///
  /// In en, this message translates to:
  /// **'Those photos aren\'t on {device} any more.'**
  String failMissing(String device);

  /// No description provided for @failOther.
  ///
  /// In en, this message translates to:
  /// **'The transfer stopped. Try again.'**
  String get failOther;

  /// Switch on a computer's page on the phone. Off by default.
  ///
  /// In en, this message translates to:
  /// **'Let {device} see your photos'**
  String permissionLabel(String device);

  /// No description provided for @permissionDetail.
  ///
  /// In en, this message translates to:
  /// **'Recent photos and screenshots, while Ferret runs. {device} can look and save, never delete.'**
  String permissionDetail(String device);

  /// No description provided for @permissionDetailLimited.
  ///
  /// In en, this message translates to:
  /// **'Ferret sees only the photos you picked. Change it in Settings, Photos.'**
  String get permissionDetailLimited;

  /// No description provided for @permissionDetailDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off for Ferret. Turn it on in Settings, Photos.'**
  String get permissionDetailDenied;

  /// No description provided for @noticeAskTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to see your photos'**
  String noticeAskTitle(String device);

  /// No description provided for @noticeAskBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose what it can see.'**
  String get noticeAskBody;

  /// No description provided for @settingsFull.
  ///
  /// In en, this message translates to:
  /// **'Ferret can see all your photos.'**
  String get settingsFull;

  /// No description provided for @settingsLimited.
  ///
  /// In en, this message translates to:
  /// **'Ferret sees only the photos you picked.'**
  String get settingsLimited;

  /// No description provided for @settingsDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off for Ferret.'**
  String get settingsDenied;

  /// No description provided for @settingsNotAsked.
  ///
  /// In en, this message translates to:
  /// **'Ferret asks for photo access when you share photos with a computer.'**
  String get settingsNotAsked;

  /// No description provided for @settingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photos can\'t be read right now.'**
  String get settingsUnavailable;

  /// No description provided for @allowPhotos.
  ///
  /// In en, this message translates to:
  /// **'Allow photos'**
  String get allowPhotos;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @settingsPerDevice.
  ///
  /// In en, this message translates to:
  /// **'Choose which computers see your photos on each computer\'s page, under What it can use. Nothing is ever deleted from here.'**
  String get settingsPerDevice;

  /// No description provided for @settingsSharing.
  ///
  /// In en, this message translates to:
  /// **'Shared with: {devices}'**
  String settingsSharing(String devices);

  /// No description provided for @settingsSharingNone.
  ///
  /// In en, this message translates to:
  /// **'Not shared with any computer.'**
  String get settingsSharingNone;

  /// No description provided for @dragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag a photo into any app to drop it there.'**
  String get dragHint;
}

class _PhotosLocalizationsDelegate
    extends LocalizationsDelegate<PhotosLocalizations> {
  const _PhotosLocalizationsDelegate();

  @override
  Future<PhotosLocalizations> load(Locale locale) {
    return SynchronousFuture<PhotosLocalizations>(
      lookupPhotosLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_PhotosLocalizationsDelegate old) => false;
}

PhotosLocalizations lookupPhotosLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return PhotosLocalizationsEn();
    case 'vi':
      return PhotosLocalizationsVi();
  }

  throw FlutterError(
    'PhotosLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
