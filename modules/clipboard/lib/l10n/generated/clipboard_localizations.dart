import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'clipboard_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ClipboardLocalizations
/// returned by `ClipboardLocalizations.of(context)`.
///
/// Applications need to include `ClipboardLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/clipboard_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ClipboardLocalizations.localizationsDelegates,
///   supportedLocales: ClipboardLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ClipboardLocalizations.supportedLocales
/// property.
abstract class ClipboardLocalizations {
  ClipboardLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ClipboardLocalizations of(BuildContext context) {
    return Localizations.of<ClipboardLocalizations>(
      context,
      ClipboardLocalizations,
    )!;
  }

  static const LocalizationsDelegate<ClipboardLocalizations> delegate =
      _ClipboardLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get title;

  /// No description provided for @cardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Copy something here and paste it on your other devices.'**
  String get cardEmpty;

  /// No description provided for @cardEmptyManual.
  ///
  /// In en, this message translates to:
  /// **'Copy something, then tap Send clipboard to paste it on your other devices.'**
  String get cardEmptyManual;

  /// No description provided for @statusWithTime.
  ///
  /// In en, this message translates to:
  /// **'{status} · {time}'**
  String statusWithTime(String status, String time);

  /// No description provided for @copiedFrom.
  ///
  /// In en, this message translates to:
  /// **'Copied from {device}'**
  String copiedFrom(String device);

  /// No description provided for @waitingToCopyFrom.
  ///
  /// In en, this message translates to:
  /// **'From {device}, not on your clipboard yet'**
  String waitingToCopyFrom(String device);

  /// No description provided for @sentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {devices}'**
  String sentTo(String devices);

  /// No description provided for @sentNowhere.
  ///
  /// In en, this message translates to:
  /// **'Copied here, no device connected'**
  String get sentNowhere;

  /// No description provided for @skippedSensitive.
  ///
  /// In en, this message translates to:
  /// **'Not synced: marked as private'**
  String get skippedSensitive;

  /// No description provided for @skippedImagesOff.
  ///
  /// In en, this message translates to:
  /// **'Not synced: images are off'**
  String get skippedImagesOff;

  /// No description provided for @skippedTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Not synced: too large'**
  String get skippedTooLarge;

  /// No description provided for @writeFailed.
  ///
  /// In en, this message translates to:
  /// **'From {device}, but Ferret couldn\'t put it on the clipboard'**
  String writeFailed(String device);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String timeMinutes(int count);

  /// No description provided for @timeHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String timeHours(int count);

  /// No description provided for @timeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{yesterday} other{{count} days ago}}'**
  String timeDays(int count);

  /// No description provided for @imageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageLabel;

  /// No description provided for @privateCleared.
  ///
  /// In en, this message translates to:
  /// **'Private item, cleared from memory'**
  String get privateCleared;

  /// No description provided for @privateHidden.
  ///
  /// In en, this message translates to:
  /// **'Private item'**
  String get privateHidden;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @sendClipboard.
  ///
  /// In en, this message translates to:
  /// **'Send clipboard'**
  String get sendClipboard;

  /// No description provided for @limitAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android doesn\'t let apps read your clipboard in the background. Copy, then tap Send clipboard here, in the Ferret notification or in the Quick Settings tile.'**
  String get limitAndroid;

  /// No description provided for @limitIos.
  ///
  /// In en, this message translates to:
  /// **'iPhone only lets apps read your clipboard when you ask. Copy, then tap Send clipboard.'**
  String get limitIos;

  /// No description provided for @resultSent.
  ///
  /// In en, this message translates to:
  /// **'Sent.'**
  String get resultSent;

  /// No description provided for @resultNothingToSend.
  ///
  /// In en, this message translates to:
  /// **'The clipboard is empty, or holds something other than text or an image.'**
  String get resultNothingToSend;

  /// No description provided for @resultDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already sent.'**
  String get resultDuplicate;

  /// No description provided for @resultSensitive.
  ///
  /// In en, this message translates to:
  /// **'Not sent: the app you copied from marked it as private. Turn on Private items below to send these.'**
  String get resultSensitive;

  /// No description provided for @resultImagesOff.
  ///
  /// In en, this message translates to:
  /// **'Not sent: images are off. Turn on Images below to send them.'**
  String get resultImagesOff;

  /// No description provided for @resultTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Not sent: it\'s bigger than the size limit.'**
  String get resultTooLarge;

  /// No description provided for @resultNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No device is connected. Open Ferret on your other device and keep it on the same network.'**
  String get resultNoDevices;

  /// No description provided for @resultFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach your devices. Check they\'re on the same network, then try again.'**
  String get resultFailed;

  /// No description provided for @settingsAutoSend.
  ///
  /// In en, this message translates to:
  /// **'Send automatically'**
  String get settingsAutoSend;

  /// No description provided for @settingsAutoSendBody.
  ///
  /// In en, this message translates to:
  /// **'Send what you copy here to your connected devices.'**
  String get settingsAutoSendBody;

  /// No description provided for @settingsAutoSendBodyManual.
  ///
  /// In en, this message translates to:
  /// **'Your phone only allows this for copies made inside Ferret. Use Send clipboard for the rest.'**
  String get settingsAutoSendBodyManual;

  /// No description provided for @settingsAutoReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive automatically'**
  String get settingsAutoReceive;

  /// No description provided for @settingsAutoReceiveBody.
  ///
  /// In en, this message translates to:
  /// **'Put what your devices send straight on this clipboard. When off, use Copy on the card.'**
  String get settingsAutoReceiveBody;

  /// No description provided for @settingsImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get settingsImages;

  /// No description provided for @settingsImagesBody.
  ///
  /// In en, this message translates to:
  /// **'Sync copied images up to {megabytes} MB.'**
  String settingsImagesBody(int megabytes);

  /// No description provided for @settingsSensitive.
  ///
  /// In en, this message translates to:
  /// **'Private items'**
  String get settingsSensitive;

  /// No description provided for @settingsSensitiveBody.
  ///
  /// In en, this message translates to:
  /// **'Sync items that password managers mark as private. They leave memory after {minutes} min.'**
  String settingsSensitiveBody(int minutes);

  /// No description provided for @settingsHistory.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{History is empty. It stays in memory, never on disk.} =1{1 item in history, in memory only.} other{{count} items in history, in memory only.}}'**
  String settingsHistory(int count);

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get settingsClearHistory;
}

class _ClipboardLocalizationsDelegate
    extends LocalizationsDelegate<ClipboardLocalizations> {
  const _ClipboardLocalizationsDelegate();

  @override
  Future<ClipboardLocalizations> load(Locale locale) {
    return SynchronousFuture<ClipboardLocalizations>(
      lookupClipboardLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_ClipboardLocalizationsDelegate old) => false;
}

ClipboardLocalizations lookupClipboardLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ClipboardLocalizationsEn();
  }

  throw FlutterError(
    'ClipboardLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
