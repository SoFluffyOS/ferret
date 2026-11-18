import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'drop_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of DropLocalizations
/// returned by `DropLocalizations.of(context)`.
///
/// Applications need to include `DropLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/drop_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: DropLocalizations.localizationsDelegates,
///   supportedLocales: DropLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the DropLocalizations.supportedLocales
/// property.
abstract class DropLocalizations {
  DropLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static DropLocalizations of(BuildContext context) {
    return Localizations.of<DropLocalizations>(context, DropLocalizations)!;
  }

  static const LocalizationsDelegate<DropLocalizations> delegate =
      _DropLocalizationsDelegate();

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
  /// **'Drop'**
  String get title;

  /// No description provided for @cardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Drop files on Ferret, or pick Send files… on a device.'**
  String get cardEmpty;

  /// No description provided for @sendFiles.
  ///
  /// In en, this message translates to:
  /// **'Send files…'**
  String get sendFiles;

  /// No description provided for @clearFinished.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFinished;

  /// No description provided for @transferFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{name}} other{{count} files}}'**
  String transferFiles(int count, String name);

  /// No description provided for @transferText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get transferText;

  /// No description provided for @statusWaitingOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {device} to accept…'**
  String statusWaitingOutgoing(String device);

  /// No description provided for @statusWaitingIncoming.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to send this'**
  String statusWaitingIncoming(String device);

  /// No description provided for @statusSending.
  ///
  /// In en, this message translates to:
  /// **'To {device} · {done} of {total}'**
  String statusSending(String device, String done, String total);

  /// No description provided for @statusReceiving.
  ///
  /// In en, this message translates to:
  /// **'From {device} · {done} of {total}'**
  String statusReceiving(String device, String done, String total);

  /// No description provided for @statusSpeed.
  ///
  /// In en, this message translates to:
  /// **'{speed}/s'**
  String statusSpeed(String speed);

  /// No description provided for @statusSpeedEta.
  ///
  /// In en, this message translates to:
  /// **'{speed}/s · {eta} left'**
  String statusSpeedEta(String speed, String eta);

  /// No description provided for @statusVerifying.
  ///
  /// In en, this message translates to:
  /// **'Checking the file…'**
  String get statusVerifying;

  /// No description provided for @statusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {device} ✓'**
  String statusSent(String device);

  /// No description provided for @statusReceived.
  ///
  /// In en, this message translates to:
  /// **'Saved ✓ · from {device}'**
  String statusReceived(String device);

  /// No description provided for @statusTextReceived.
  ///
  /// In en, this message translates to:
  /// **'From {device}'**
  String statusTextReceived(String device);

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @failureDeclined.
  ///
  /// In en, this message translates to:
  /// **'{device} said no.'**
  String failureDeclined(String device);

  /// No description provided for @failureTimedOut.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer in time.'**
  String failureTimedOut(String device);

  /// No description provided for @failureDisconnected.
  ///
  /// In en, this message translates to:
  /// **'{device} went offline. It continues when it\'s back.'**
  String failureDisconnected(String device);

  /// No description provided for @failureNotConnected.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t connected. Open Ferret on it, then retry.'**
  String failureNotConnected(String device);

  /// No description provided for @failureUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} needs a newer Ferret to receive files.'**
  String failureUnsupported(String device);

  /// No description provided for @failureStorage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t write the file. Check free space and the receive folder.'**
  String get failureStorage;

  /// No description provided for @failureChecksum.
  ///
  /// In en, this message translates to:
  /// **'The file arrived damaged. Retry sends it again.'**
  String get failureChecksum;

  /// No description provided for @failureSourceChanged.
  ///
  /// In en, this message translates to:
  /// **'The file changed or moved while it was being sent.'**
  String get failureSourceChanged;

  /// No description provided for @failureCancelledByPeer.
  ///
  /// In en, this message translates to:
  /// **'{device} cancelled.'**
  String failureCancelledByPeer(String device);

  /// No description provided for @failureUnknownTransfer.
  ///
  /// In en, this message translates to:
  /// **'{device} lost track of this transfer. Send it again.'**
  String failureUnknownTransfer(String device);

  /// No description provided for @failureProtocol.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with {device}. Retry to continue.'**
  String failureProtocol(String device);

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @actionReveal.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get actionReveal;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// No description provided for @actionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get actionDecline;

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

  /// No description provided for @noticeSending.
  ///
  /// In en, this message translates to:
  /// **'Sending to {device}'**
  String noticeSending(String device);

  /// No description provided for @noticeReceiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving from {device}'**
  String noticeReceiving(String device);

  /// No description provided for @noticeSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {device}'**
  String noticeSent(String device);

  /// No description provided for @noticeReceived.
  ///
  /// In en, this message translates to:
  /// **'Received from {device}'**
  String noticeReceived(String device);

  /// No description provided for @noticeText.
  ///
  /// In en, this message translates to:
  /// **'Text from {device}'**
  String noticeText(String device);

  /// No description provided for @noticeFailed.
  ///
  /// In en, this message translates to:
  /// **'Transfer with {device} stopped'**
  String noticeFailed(String device);

  /// No description provided for @noticeOffer.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to send you something'**
  String noticeOffer(String device);

  /// No description provided for @noticeNoDevice.
  ///
  /// In en, this message translates to:
  /// **'No device to send to'**
  String get noticeNoDevice;

  /// No description provided for @noticeNoDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Connect one of your paired devices, then try again.'**
  String get noticeNoDeviceBody;

  /// No description provided for @noticeNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to send'**
  String get noticeNothing;

  /// No description provided for @noticeNothingBody.
  ///
  /// In en, this message translates to:
  /// **'Folders can\'t be sent yet. Pick the files inside instead.'**
  String get noticeNothingBody;

  /// No description provided for @pickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to which device?'**
  String get pickerTitle;

  /// No description provided for @settingsReceiveFolder.
  ///
  /// In en, this message translates to:
  /// **'Receive folder'**
  String get settingsReceiveFolder;

  /// No description provided for @settingsChange.
  ///
  /// In en, this message translates to:
  /// **'Change…'**
  String get settingsChange;

  /// No description provided for @settingsUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get settingsUseDefault;

  /// No description provided for @settingsFolderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name in Downloads'**
  String get settingsFolderName;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @settingsAutoAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept from my devices'**
  String get settingsAutoAccept;

  /// No description provided for @settingsAutoAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'Files from your paired devices go straight to the receive folder. Turn this off to approve each one.'**
  String get settingsAutoAcceptBody;

  /// No description provided for @sizeBytes.
  ///
  /// In en, this message translates to:
  /// **'{value} B'**
  String sizeBytes(String value);

  /// No description provided for @sizeKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String sizeKilobytes(String value);

  /// No description provided for @sizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String sizeMegabytes(String value);

  /// No description provided for @sizeGigabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} GB'**
  String sizeGigabytes(String value);

  /// No description provided for @etaSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String etaSeconds(int seconds);

  /// No description provided for @etaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String etaMinutes(int minutes);

  /// No description provided for @etaHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String etaHours(int hours, int minutes);
}

class _DropLocalizationsDelegate
    extends LocalizationsDelegate<DropLocalizations> {
  const _DropLocalizationsDelegate();

  @override
  Future<DropLocalizations> load(Locale locale) {
    return SynchronousFuture<DropLocalizations>(
      lookupDropLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_DropLocalizationsDelegate old) => false;
}

DropLocalizations lookupDropLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return DropLocalizationsEn();
  }

  throw FlutterError(
    'DropLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
