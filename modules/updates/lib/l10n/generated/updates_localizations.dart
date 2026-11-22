import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'updates_localizations_en.dart';
import 'updates_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of UpdatesLocalizations
/// returned by `UpdatesLocalizations.of(context)`.
///
/// Applications need to include `UpdatesLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/updates_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: UpdatesLocalizations.localizationsDelegates,
///   supportedLocales: UpdatesLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the UpdatesLocalizations.supportedLocales
/// property.
abstract class UpdatesLocalizations {
  UpdatesLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static UpdatesLocalizations of(BuildContext context) {
    return Localizations.of<UpdatesLocalizations>(
      context,
      UpdatesLocalizations,
    )!;
  }

  static const LocalizationsDelegate<UpdatesLocalizations> delegate =
      _UpdatesLocalizationsDelegate();

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

  /// Heading of the update section in About.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get title;

  /// Switch that turns the daily update check on or off.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkSwitch;

  /// Says what the update check does and what it sends.
  ///
  /// In en, this message translates to:
  /// **'Once a day, Ferret asks GitHub for its newest version. It sends nothing about you or your devices.'**
  String get checkSwitchBody;

  /// Switch: also offer test versions (pre-releases).
  ///
  /// In en, this message translates to:
  /// **'Include beta versions'**
  String get betaSwitch;

  /// Explains beta versions.
  ///
  /// In en, this message translates to:
  /// **'Try what\'s next before everyone else. Betas may have rough edges.'**
  String get betaSwitchBody;

  /// Button: check for an update right away.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkNow;

  /// Tooltip of Check now.
  ///
  /// In en, this message translates to:
  /// **'Ask GitHub for Ferret\'s newest version now'**
  String get checkNowTooltip;

  /// Status while asking GitHub for the newest version.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// Status: no update.
  ///
  /// In en, this message translates to:
  /// **'Ferret {version} is the newest version.'**
  String upToDate(String version);

  /// Status: the check failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach GitHub. Try again later. On a work network, a proxy or firewall may block it.'**
  String get checkFailed;

  /// Status while the check is off.
  ///
  /// In en, this message translates to:
  /// **'Ferret doesn\'t check for updates. You have {version}.'**
  String statusOff(String version);

  /// Card title: a newer version can be installed.
  ///
  /// In en, this message translates to:
  /// **'Ferret {version} is ready'**
  String ready(String version);

  /// Card title where Ferret can't install it itself.
  ///
  /// In en, this message translates to:
  /// **'Ferret {version} is out'**
  String readyOut(String version);

  /// Card subtitle: the installed version.
  ///
  /// In en, this message translates to:
  /// **'You have {version}'**
  String youHave(String version);

  /// Card line for Flatpak/.deb/Snap installs.
  ///
  /// In en, this message translates to:
  /// **'Update it with your package manager or software center.'**
  String get packageManager;

  /// Card line where Ferret runs from a folder it can't update.
  ///
  /// In en, this message translates to:
  /// **'Download it from the website to install it.'**
  String get manualInstall;

  /// Button: download, check and install the update.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// Tooltip of Install.
  ///
  /// In en, this message translates to:
  /// **'Download, check and install Ferret {version}, then restart'**
  String installTooltip(String version);

  /// Button: show the release notes.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNew;

  /// Title of the release notes dialog.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in Ferret {version}'**
  String whatsNewTitle(String version);

  /// Shown when a release has no notes.
  ///
  /// In en, this message translates to:
  /// **'This version came without notes.'**
  String get noNotes;

  /// Button in the What's new dialog: close it without installing.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// Closes the dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Button: open the release page in the browser.
  ///
  /// In en, this message translates to:
  /// **'Download page'**
  String get downloadPage;

  /// Tooltip of Download page.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret\'s download page in your browser'**
  String get downloadPageTooltip;

  /// Progress line while downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String downloading(int percent);

  /// Progress line while the size is unknown.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloadingNoSize;

  /// Progress line while checking the checksum and signature.
  ///
  /// In en, this message translates to:
  /// **'Checking the download…'**
  String get verifying;

  /// Progress line while installing.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get installing;

  /// Line while Ferret quits to restart.
  ///
  /// In en, this message translates to:
  /// **'Ferret restarts in a moment.'**
  String get restarting;

  /// Stops the download.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Retries the update.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Card title when the update was refused or failed.
  ///
  /// In en, this message translates to:
  /// **'Update not installed'**
  String get notInstalled;

  /// Why: download failed.
  ///
  /// In en, this message translates to:
  /// **'The download didn\'t finish. Check your connection and try again.'**
  String get downloadFailed;

  /// Why: no asset for this platform.
  ///
  /// In en, this message translates to:
  /// **'This release has no file for this system yet.'**
  String get noFile;

  /// Why: no SHA256SUMS entry.
  ///
  /// In en, this message translates to:
  /// **'This release lists no checksum for the file, so Ferret can\'t check it. Nothing was installed.'**
  String get checksumMissing;

  /// Why: SHA-256 mismatch.
  ///
  /// In en, this message translates to:
  /// **'The download doesn\'t match the checksum on GitHub, so it may be damaged or changed. Nothing was installed.'**
  String get checksumMismatch;

  /// Why: missing or broken signature.
  ///
  /// In en, this message translates to:
  /// **'The download isn\'t properly signed. Nothing was installed.'**
  String get notSigned;

  /// Why: signed by someone else.
  ///
  /// In en, this message translates to:
  /// **'The download isn\'t signed by Ferret\'s developer. Nothing was installed.'**
  String get wrongPublisher;

  /// Why: Gatekeeper refused.
  ///
  /// In en, this message translates to:
  /// **'Apple hasn\'t checked this download (it isn\'t notarized). Nothing was installed.'**
  String get notNotarized;

  /// Why: the running Windows copy has no signature.
  ///
  /// In en, this message translates to:
  /// **'This copy of Ferret isn\'t signed, so it can\'t tell who made the update. Install it from the download page.'**
  String get unsignedHere;

  /// Why: install step failed.
  ///
  /// In en, this message translates to:
  /// **'Ferret couldn\'t install the update. Install it from the download page.'**
  String get installFailed;

  /// Card title on Android before asking for Install unknown apps.
  ///
  /// In en, this message translates to:
  /// **'Allow Ferret to install its update'**
  String get permissionTitle;

  /// Why the permission is needed.
  ///
  /// In en, this message translates to:
  /// **'Android asks once. Ferret only installs its own updates, checked first.'**
  String get permissionBody;

  /// Button: opens Android's Install unknown apps switch.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// Tooltip of Open settings.
  ///
  /// In en, this message translates to:
  /// **'Open Android\'s Install unknown apps switch for Ferret'**
  String get openSettingsTooltip;

  /// Card line while Android's own install prompt is up.
  ///
  /// In en, this message translates to:
  /// **'Confirm the update in Android\'s prompt.'**
  String get confirmOnPhone;

  /// Button: show Android's install prompt again.
  ///
  /// In en, this message translates to:
  /// **'Show prompt'**
  String get showPrompt;

  /// Tooltip of Show prompt.
  ///
  /// In en, this message translates to:
  /// **'Show Android\'s install prompt again'**
  String get showPromptTooltip;

  /// Card title on a Mac when Ferret couldn't replace itself.
  ///
  /// In en, this message translates to:
  /// **'Drag Ferret to Applications'**
  String get dragTitle;

  /// Why the DMG opened.
  ///
  /// In en, this message translates to:
  /// **'Ferret can\'t replace itself in that folder without an administrator, so the checked update is open in Finder.'**
  String get dragBody;
}

class _UpdatesLocalizationsDelegate
    extends LocalizationsDelegate<UpdatesLocalizations> {
  const _UpdatesLocalizationsDelegate();

  @override
  Future<UpdatesLocalizations> load(Locale locale) {
    return SynchronousFuture<UpdatesLocalizations>(
      lookupUpdatesLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_UpdatesLocalizationsDelegate old) => false;
}

UpdatesLocalizations lookupUpdatesLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return UpdatesLocalizationsEn();
    case 'vi':
      return UpdatesLocalizationsVi();
  }

  throw FlutterError(
    'UpdatesLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
