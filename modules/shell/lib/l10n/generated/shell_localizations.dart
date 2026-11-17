import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'shell_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ShellLocalizations
/// returned by `ShellLocalizations.of(context)`.
///
/// Applications need to include `ShellLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/shell_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ShellLocalizations.localizationsDelegates,
///   supportedLocales: ShellLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ShellLocalizations.supportedLocales
/// property.
abstract class ShellLocalizations {
  ShellLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ShellLocalizations of(BuildContext context) {
    return Localizations.of<ShellLocalizations>(context, ShellLocalizations)!;
  }

  static const LocalizationsDelegate<ShellLocalizations> delegate =
      _ShellLocalizationsDelegate();

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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Ferret'**
  String get appName;

  /// No description provided for @homeYourDevices.
  ///
  /// In en, this message translates to:
  /// **'Your devices'**
  String get homeYourDevices;

  /// No description provided for @homeNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get homeNearby;

  /// No description provided for @homeNoDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No devices yet'**
  String get homeNoDevicesTitle;

  /// No description provided for @homeNoDevicesBody.
  ///
  /// In en, this message translates to:
  /// **'Pair your phone and your computer to start passing things between them.'**
  String get homeNoDevicesBody;

  /// No description provided for @homePairDevice.
  ///
  /// In en, this message translates to:
  /// **'Pair a device'**
  String get homePairDevice;

  /// No description provided for @deviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get deviceConnected;

  /// No description provided for @deviceOffline.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get deviceOffline;

  /// No description provided for @deviceLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String deviceLastSeen(String time);

  /// No description provided for @nearbyPairHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to pair'**
  String get nearbyPairHint;

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair a device'**
  String get pairTitle;

  /// No description provided for @pairShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show code'**
  String get pairShowCode;

  /// No description provided for @pairEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Use a link'**
  String get pairEnterCode;

  /// No description provided for @pairShowCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Scan this code with Ferret on your other device, or open the link there.'**
  String get pairShowCodeBody;

  /// No description provided for @pairCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get pairCopyLink;

  /// No description provided for @pairLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get pairLinkCopied;

  /// No description provided for @pairExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes} min'**
  String pairExpiresIn(int minutes);

  /// No description provided for @pairNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get pairNewCode;

  /// No description provided for @pairLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Pairing link'**
  String get pairLinkLabel;

  /// No description provided for @pairLinkHint.
  ///
  /// In en, this message translates to:
  /// **'ferret://pair?o=…'**
  String get pairLinkHint;

  /// No description provided for @pairLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a Ferret pairing link.'**
  String get pairLinkInvalid;

  /// No description provided for @pairAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Or connect to an address'**
  String get pairAddressLabel;

  /// No description provided for @pairAddressHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.20:47640'**
  String get pairAddressHint;

  /// No description provided for @pairConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get pairConnect;

  /// No description provided for @pairCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare the codes'**
  String get pairCompareTitle;

  /// No description provided for @pairCompareBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure {device} shows the same code, then confirm there.'**
  String pairCompareBody(String device);

  /// No description provided for @pairWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other device…'**
  String get pairWaiting;

  /// No description provided for @pairSuccess.
  ///
  /// In en, this message translates to:
  /// **'Paired with {device}'**
  String pairSuccess(String device);

  /// No description provided for @pairFailedUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach that device. Are both on the same network?'**
  String get pairFailedUnreachable;

  /// No description provided for @pairFailedRejected.
  ///
  /// In en, this message translates to:
  /// **'The other device said no.'**
  String get pairFailedRejected;

  /// No description provided for @pairFailedExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Show a new one.'**
  String get pairFailedExpired;

  /// No description provided for @pairFailedBadProof.
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t match. Try a new one.'**
  String get pairFailedBadProof;

  /// No description provided for @pairFailedWrongDevice.
  ///
  /// In en, this message translates to:
  /// **'A different device answered. Pairing stopped to keep you safe.'**
  String get pairFailedWrongDevice;

  /// No description provided for @pairFailedTimedOut.
  ///
  /// In en, this message translates to:
  /// **'No answer in time.'**
  String get pairFailedTimedOut;

  /// No description provided for @pairFailedProtocol.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while pairing.'**
  String get pairFailedProtocol;

  /// No description provided for @promptTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair with {device}?'**
  String promptTitle(String device);

  /// No description provided for @promptBody.
  ///
  /// In en, this message translates to:
  /// **'Only accept if {device} shows this code too.'**
  String promptBody(String device);

  /// No description provided for @promptAccept.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get promptAccept;

  /// No description provided for @promptReject.
  ///
  /// In en, this message translates to:
  /// **'Don\'t pair'**
  String get promptReject;

  /// No description provided for @deviceTitleId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceTitleId;

  /// No description provided for @deviceActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get deviceActions;

  /// No description provided for @deviceUnpair.
  ///
  /// In en, this message translates to:
  /// **'Unpair'**
  String get deviceUnpair;

  /// No description provided for @deviceUnpairConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpair {device}?'**
  String deviceUnpairConfirmTitle(String device);

  /// No description provided for @deviceUnpairConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Both devices forget each other. You can pair again any time.'**
  String get deviceUnpairConfirmBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsThisDevice;

  /// No description provided for @settingsDeviceId.
  ///
  /// In en, this message translates to:
  /// **'ID {id}'**
  String settingsDeviceId(String id);

  /// No description provided for @settingsPort.
  ///
  /// In en, this message translates to:
  /// **'Listening on port {port}'**
  String settingsPort(int port);

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret talks only to devices you paired, directly on your network, end-to-end encrypted. No account, no cloud, no telemetry.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit Ferret'**
  String get settingsQuit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @menuOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret'**
  String get menuOpen;

  /// No description provided for @menuPair.
  ///
  /// In en, this message translates to:
  /// **'Pair a Device…'**
  String get menuPair;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings…'**
  String get menuSettings;

  /// No description provided for @menuQuit.
  ///
  /// In en, this message translates to:
  /// **'Quit Ferret'**
  String get menuQuit;
}

class _ShellLocalizationsDelegate
    extends LocalizationsDelegate<ShellLocalizations> {
  const _ShellLocalizationsDelegate();

  @override
  Future<ShellLocalizations> load(Locale locale) {
    return SynchronousFuture<ShellLocalizations>(
      lookupShellLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_ShellLocalizationsDelegate old) => false;
}

ShellLocalizations lookupShellLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ShellLocalizationsEn();
  }

  throw FlutterError(
    'ShellLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
