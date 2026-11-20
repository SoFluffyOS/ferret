import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'drop_localizations_en.dart';
import 'drop_localizations_vi.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Name of the file-transfer feature (card and settings title)
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get title;

  /// No description provided for @cardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Drop files here to send them to your devices.'**
  String get cardEmpty;

  /// No description provided for @cardEmptyPhone.
  ///
  /// In en, this message translates to:
  /// **'Send photos and files to your other devices.'**
  String get cardEmptyPhone;

  /// No description provided for @otherApps.
  ///
  /// In en, this message translates to:
  /// **'Let other phones send you files'**
  String get otherApps;

  /// No description provided for @sendFiles.
  ///
  /// In en, this message translates to:
  /// **'Send files'**
  String get sendFiles;

  /// No description provided for @activityFrom.
  ///
  /// In en, this message translates to:
  /// **'{what} from {device}'**
  String activityFrom(String what, String device);

  /// No description provided for @activityTo.
  ///
  /// In en, this message translates to:
  /// **'{what} to {device}'**
  String activityTo(String what, String device);

  /// No description provided for @activityText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get activityText;

  /// No description provided for @activitySavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {folder}'**
  String activitySavedTo(String folder);

  /// No description provided for @activitySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get activitySaved;

  /// No description provided for @activitySent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get activitySent;

  /// No description provided for @activityProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String activityProgress(String done, String total);

  /// No description provided for @activityProgressEta.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} · {eta} left'**
  String activityProgressEta(String done, String total, String eta);

  /// Outgoing transfer waiting for the other device to accept
  ///
  /// In en, this message translates to:
  /// **'Waiting for an answer…'**
  String get activityWaiting;

  /// No description provided for @activityOffer.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to send'**
  String activityOffer(String device);

  /// No description provided for @activityOfferSize.
  ///
  /// In en, this message translates to:
  /// **'{what} · {size}'**
  String activityOfferSize(String what, String size);

  /// No description provided for @actionRevealFinder.
  ///
  /// In en, this message translates to:
  /// **'Show in Finder'**
  String get actionRevealFinder;

  /// Offer on Home: let one person without Ferret send one file here
  ///
  /// In en, this message translates to:
  /// **'Receive a file from a guest'**
  String get guestTitle;

  /// No description provided for @guestBody.
  ///
  /// In en, this message translates to:
  /// **'A phone without Ferret can send one file here with Quick Share or LocalSend, for 10 minutes or until the first file arrives.'**
  String get guestBody;

  /// No description provided for @guestBodyLocalSend.
  ///
  /// In en, this message translates to:
  /// **'A phone without Ferret can send one file here with LocalSend, for 10 minutes or until the first file arrives.'**
  String get guestBodyLocalSend;

  /// No description provided for @guestAction.
  ///
  /// In en, this message translates to:
  /// **'Allow once'**
  String get guestAction;

  /// No description provided for @guestWaiting.
  ///
  /// In en, this message translates to:
  /// **'Open for one file from a guest. It closes once the file arrives.'**
  String get guestWaiting;

  /// Button: remove finished transfers from the list
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
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
  /// **'{device} declined.'**
  String failureDeclined(String device);

  /// No description provided for @failureTimedOut.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer in time.'**
  String failureTimedOut(String device);

  /// No description provided for @failureDisconnected.
  ///
  /// In en, this message translates to:
  /// **'{device} went offline. It continues when {device} is back.'**
  String failureDisconnected(String device);

  /// No description provided for @failureDisconnectedSending.
  ///
  /// In en, this message translates to:
  /// **'{device} went offline. It goes on when {device} is back.'**
  String failureDisconnectedSending(String device);

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused at {done} of {total}. It goes on when {device} is back.'**
  String statusPaused(String done, String total, String device);

  /// No description provided for @statusWaitingForDevice.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {device}. It goes as soon as {device} is back.'**
  String statusWaitingForDevice(String device);

  /// No description provided for @noticePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused with {device}'**
  String noticePaused(String device);

  /// No description provided for @actionTryNow.
  ///
  /// In en, this message translates to:
  /// **'Try now'**
  String get actionTryNow;

  /// No description provided for @failureNotConnected.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t connected. On {device}: open Ferret, then try again here.'**
  String failureNotConnected(String device);

  /// No description provided for @failureUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} needs a newer Ferret to receive files.'**
  String failureUnsupported(String device);

  /// No description provided for @failureStorage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the file. Check free space and the receive folder.'**
  String get failureStorage;

  /// No description provided for @failureStorageSending.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t save the file. It may be out of space.'**
  String failureStorageSending(String device);

  /// Receiving side: files turned down before they came because they don't fit. name is the file, folder or 'N files'; needed and free are sizes like '2 GB'.
  ///
  /// In en, this message translates to:
  /// **'Not enough space for {name}: needs {needed}, {free} free'**
  String failureOutOfSpace(String name, String needed, String free);

  /// Sending side: the receiving device turned the files down because they don't fit there.
  ///
  /// In en, this message translates to:
  /// **'{device} is out of space: needs {needed}, {free} free'**
  String failureOutOfSpaceSending(String device, String needed, String free);

  /// Android: opens the system's storage settings, to make room after files didn't fit.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get actionStorageSettings;

  /// No description provided for @failureChecksum.
  ///
  /// In en, this message translates to:
  /// **'The file arrived damaged. Try again to send it once more.'**
  String get failureChecksum;

  /// No description provided for @failureSourceChanged.
  ///
  /// In en, this message translates to:
  /// **'The file changed or moved while it was being sent. Send it again.'**
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
  /// **'Something went wrong with {device}. Try again to continue.'**
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
  /// **'Try again'**
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
  /// **'Open Ferret on one of your devices, then try again.'**
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

  /// No description provided for @failurePinRequired.
  ///
  /// In en, this message translates to:
  /// **'{device} asks for a PIN. Enter the one it shows.'**
  String failurePinRequired(String device);

  /// No description provided for @failureTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong PINs for {device}. Wait a moment, then try again.'**
  String failureTooManyAttempts(String device);

  /// No description provided for @failureBusy.
  ///
  /// In en, this message translates to:
  /// **'{device} is busy with another transfer. Try again when it\'s done.'**
  String failureBusy(String device);

  /// No description provided for @failureUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach {device}. On {device}: keep LocalSend open, on the same Wi-Fi.'**
  String failureUnreachable(String device);

  /// No description provided for @failureUntrusted.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t the device it said it was. Nothing was sent.'**
  String failureUntrusted(String device);

  /// No description provided for @actionEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get actionEnterPin;

  /// No description provided for @pinTitle.
  ///
  /// In en, this message translates to:
  /// **'PIN for {device}'**
  String pinTitle(String device);

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @pinSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get pinSend;

  /// No description provided for @offerFrom.
  ///
  /// In en, this message translates to:
  /// **'{model} · {address}'**
  String offerFrom(String model, String address);

  /// Short code that identifies a LocalSend sender (a certificate fingerprint), not a biometric
  ///
  /// In en, this message translates to:
  /// **'Fingerprint {fingerprint}'**
  String offerFingerprint(String fingerprint);

  /// No description provided for @offerFiles.
  ///
  /// In en, this message translates to:
  /// **'{names}'**
  String offerFiles(String names);

  /// Files offered to you: the first names, then how many more. "photo.jpg, notes.pdf and 3 more"
  ///
  /// In en, this message translates to:
  /// **'{names} and {count, plural, other{{count} more}}'**
  String offerFilesMore(String names, int count);

  /// No description provided for @offerTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}} · {size}'**
  String offerTotal(int count, String size);

  /// No description provided for @offerWarning.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t paired with Ferret. Accept only if you expect it.'**
  String offerWarning(String device);

  /// No description provided for @pickerLocalSend.
  ///
  /// In en, this message translates to:
  /// **'LocalSend'**
  String get pickerLocalSend;

  /// No description provided for @pickerLocalSendModel.
  ///
  /// In en, this message translates to:
  /// **'LocalSend · {model}'**
  String pickerLocalSendModel(String model);

  /// No description provided for @pickerScanning.
  ///
  /// In en, this message translates to:
  /// **'Looking for LocalSend devices…'**
  String get pickerScanning;

  /// No description provided for @pickerNoLocalSend.
  ///
  /// In en, this message translates to:
  /// **'No LocalSend devices found. On the other device: open LocalSend, on the same Wi-Fi.'**
  String get pickerNoLocalSend;

  /// No description provided for @pickerNoDevices.
  ///
  /// In en, this message translates to:
  /// **'None of your devices is connected.'**
  String get pickerNoDevices;

  /// No description provided for @pickerSearchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get pickerSearchAgain;

  /// No description provided for @noticeGone.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find {device}'**
  String noticeGone(String device);

  /// No description provided for @noticeGoneBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open LocalSend, then send again.'**
  String noticeGoneBody(String device);

  /// No description provided for @receiveTitle.
  ///
  /// In en, this message translates to:
  /// **'LocalSend'**
  String get receiveTitle;

  /// No description provided for @receiveOff.
  ///
  /// In en, this message translates to:
  /// **'Let devices with the LocalSend app send here.'**
  String get receiveOff;

  /// No description provided for @receiveStarting.
  ///
  /// In en, this message translates to:
  /// **'Turning on…'**
  String get receiveStarting;

  /// No description provided for @receiveTimed.
  ///
  /// In en, this message translates to:
  /// **'Visible as {alias} · {time} left'**
  String receiveTimed(String alias, String time);

  /// No description provided for @receiveAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Visible as {alias} · stays on'**
  String receiveAlwaysOn(String alias);

  /// No description provided for @receiveCannotListen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start. A firewall or another app may be blocking it.'**
  String get receiveCannotListen;

  /// No description provided for @receiveNoIdentity.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t prepare this device for LocalSend.'**
  String get receiveNoIdentity;

  /// No description provided for @receiveTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Allow 10 min'**
  String get receiveTurnOn;

  /// No description provided for @receiveTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get receiveTryAgain;

  /// No description provided for @receiveStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get receiveStop;

  /// No description provided for @settingsLocalSend.
  ///
  /// In en, this message translates to:
  /// **'Work with LocalSend'**
  String get settingsLocalSend;

  /// No description provided for @settingsLocalSendBody.
  ///
  /// In en, this message translates to:
  /// **'Send files to devices running the LocalSend app, and receive from them when you turn it on. Each file from LocalSend asks first.'**
  String get settingsLocalSendBody;

  /// No description provided for @settingsReceiveAlways.
  ///
  /// In en, this message translates to:
  /// **'Always receive from LocalSend'**
  String get settingsReceiveAlways;

  /// No description provided for @settingsReceiveAlwaysBody.
  ///
  /// In en, this message translates to:
  /// **'Keeps this device visible to LocalSend devices on your network, also after a restart. Off, it\'s visible for 10 minutes when you ask.'**
  String get settingsReceiveAlwaysBody;

  /// No description provided for @failureConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'The connection to {device} dropped. On {device}: send it again.'**
  String failureConnectionLost(String device);

  /// No description provided for @failureQuickShare.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with {device}. On {device}: send it again.'**
  String failureQuickShare(String device);

  /// No description provided for @offerPin.
  ///
  /// In en, this message translates to:
  /// **'PIN {pin}. It must match the one on {device}.'**
  String offerPin(String pin, String device);

  /// No description provided for @noticePin.
  ///
  /// In en, this message translates to:
  /// **'PIN {pin}'**
  String noticePin(String pin);

  /// No description provided for @quickShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Share'**
  String get quickShareTitle;

  /// No description provided for @quickShareOff.
  ///
  /// In en, this message translates to:
  /// **'Let Android phones without Ferret send here.'**
  String get quickShareOff;

  /// No description provided for @quickShareFinishing.
  ///
  /// In en, this message translates to:
  /// **'No longer visible. Finishing a transfer…'**
  String get quickShareFinishing;

  /// No description provided for @quickShareCannotAdvertise.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t become visible. A firewall or VPN may be blocking it.'**
  String get quickShareCannotAdvertise;

  /// No description provided for @quickShareTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Show 10 min'**
  String get quickShareTurnOn;

  /// No description provided for @settingsQuickShare.
  ///
  /// In en, this message translates to:
  /// **'Work with Quick Share'**
  String get settingsQuickShare;

  /// No description provided for @settingsQuickShareBody.
  ///
  /// In en, this message translates to:
  /// **'Android phones can send files to this device with Quick Share while you make it visible. Each file asks first.'**
  String get settingsQuickShareBody;

  /// Health line when no transfer happened yet
  ///
  /// In en, this message translates to:
  /// **'Nothing sent yet'**
  String get healthOk;

  /// No description provided for @healthArrive.
  ///
  /// In en, this message translates to:
  /// **'Arrive in {folder}'**
  String healthArrive(String folder);

  /// No description provided for @healthLastSent.
  ///
  /// In en, this message translates to:
  /// **'{name} got the last thing you sent'**
  String healthLastSent(String name);

  /// No description provided for @healthLastReceived.
  ///
  /// In en, this message translates to:
  /// **'The last thing {name} sent arrived'**
  String healthLastReceived(String name);

  /// No description provided for @healthDeclinedThere.
  ///
  /// In en, this message translates to:
  /// **'{name} declined the last thing you sent'**
  String healthDeclinedThere(String name);

  /// No description provided for @healthDeclinedHere.
  ///
  /// In en, this message translates to:
  /// **'You declined the last thing {name} sent'**
  String healthDeclinedHere(String name);

  /// No description provided for @healthCancelledThere.
  ///
  /// In en, this message translates to:
  /// **'{name} cancelled the last transfer'**
  String healthCancelledThere(String name);

  /// No description provided for @healthCancelledHere.
  ///
  /// In en, this message translates to:
  /// **'You cancelled the last transfer'**
  String get healthCancelledHere;

  /// No description provided for @healthNoAnswerThere.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t answer the last time you sent'**
  String healthNoAnswerThere(String name);

  /// No description provided for @healthNoAnswerHere.
  ///
  /// In en, this message translates to:
  /// **'The last thing {name} sent wasn\'t accepted in time'**
  String healthNoAnswerHere(String name);

  /// No description provided for @healthSendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send the files again from here.'**
  String get healthSendAgain;

  /// No description provided for @healthSendAgainThere.
  ///
  /// In en, this message translates to:
  /// **'On {name}: send the files again.'**
  String healthSendAgainThere(String name);

  /// Settings summary: received files go into this folder
  ///
  /// In en, this message translates to:
  /// **'To {folder}'**
  String summaryFolder(String folder);

  /// No description provided for @summaryOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get summaryOff;

  /// No description provided for @summaryAlwaysReceives.
  ///
  /// In en, this message translates to:
  /// **'Always receives'**
  String get summaryAlwaysReceives;

  /// No description provided for @summaryReceivingNow.
  ///
  /// In en, this message translates to:
  /// **'Receiving now'**
  String get summaryReceivingNow;

  /// No description provided for @summaryReceivesOnAsk.
  ///
  /// In en, this message translates to:
  /// **'Receives when you allow it'**
  String get summaryReceivesOnAsk;

  /// No description provided for @summaryCannotReceive.
  ///
  /// In en, this message translates to:
  /// **'Can\'t receive right now'**
  String get summaryCannotReceive;

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
  /// **'{seconds, plural, other{{seconds} s}}'**
  String etaSeconds(int seconds);

  /// No description provided for @etaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, other{{minutes} min}}'**
  String etaMinutes(int minutes);

  /// No description provided for @etaHours.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, other{{hours} h}} {minutes, plural, other{{minutes} min}}'**
  String etaHours(int hours, int minutes);

  /// No description provided for @filesDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop files here to send them to {device}.'**
  String filesDropHere(String device);

  /// No description provided for @filesPickToSend.
  ///
  /// In en, this message translates to:
  /// **'Pick photos and files to send to {device}.'**
  String filesPickToSend(String device);

  /// No description provided for @filesChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose files…'**
  String get filesChoose;

  /// No description provided for @filesOffline.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t connected. Send it files once it is.'**
  String filesOffline(String device);

  /// No description provided for @filesRecent.
  ///
  /// In en, this message translates to:
  /// **'Sent and received'**
  String get filesRecent;

  /// No description provided for @filesNone.
  ///
  /// In en, this message translates to:
  /// **'Files you send to {device}, and the ones it sends you, show here.'**
  String filesNone(String device);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// A transfer's progress line while the link to the device is slow, such as: Weak connection · 620 MB of 1.8 GB · 12 min left
  ///
  /// In en, this message translates to:
  /// **'Weak connection · {progress}'**
  String progressWeak(String progress);

  /// Link above a device's transfers when several stopped and can be tried again
  ///
  /// In en, this message translates to:
  /// **'Try all again'**
  String get actionTryAll;

  /// No description provided for @failureFoldersUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device}\'s Ferret is too old for folders. Update it, or send the files.'**
  String failureFoldersUnsupported(String device);

  /// Sends a folder's files on their own, without the folder, to a device whose Ferret can't take folders
  ///
  /// In en, this message translates to:
  /// **'Send the files'**
  String get actionSendLoose;

  /// Button that picks a folder to send with everything in it
  ///
  /// In en, this message translates to:
  /// **'Choose a folder…'**
  String get filesChooseFolder;

  /// Device action that picks a folder to send
  ///
  /// In en, this message translates to:
  /// **'Send a folder'**
  String get sendFolder;

  /// No description provided for @folderFilesDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total, plural, =1{1 file} other{{total} files}}'**
  String folderFilesDone(int done, int total);

  /// How far a folder is: '120 of 340 files · 1.2 GB', followed by 'of 3.4 GB'
  ///
  /// In en, this message translates to:
  /// **'{files} · {size}'**
  String folderProgressDone(String files, String size);

  /// No description provided for @folderSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 link or special file left out} other{{count} links or special files left out}}'**
  String folderSkipped(int count);
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_DropLocalizationsDelegate old) => false;
}

DropLocalizations lookupDropLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return DropLocalizationsEn();
    case 'vi':
      return DropLocalizationsVi();
  }

  throw FlutterError(
    'DropLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
