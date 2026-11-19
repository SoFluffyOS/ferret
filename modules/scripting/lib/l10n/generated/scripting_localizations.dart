import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'scripting_localizations_en.dart';
import 'scripting_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ScriptingLocalizations
/// returned by `ScriptingLocalizations.of(context)`.
///
/// Applications need to include `ScriptingLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/scripting_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ScriptingLocalizations.localizationsDelegates,
///   supportedLocales: ScriptingLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the ScriptingLocalizations.supportedLocales
/// property.
abstract class ScriptingLocalizations {
  ScriptingLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ScriptingLocalizations of(BuildContext context) {
    return Localizations.of<ScriptingLocalizations>(
      context,
      ScriptingLocalizations,
    )!;
  }

  static const LocalizationsDelegate<ScriptingLocalizations> delegate =
      _ScriptingLocalizationsDelegate();

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

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Scripts'**
  String get title;

  /// A notice a script on another device sent. title is what the script wrote, device the computer it ran on.
  ///
  /// In en, this message translates to:
  /// **'{title} · {device}'**
  String noticeTitle(String title, String device);

  /// Shown instead of a script's notice while previews from that device are hidden.
  ///
  /// In en, this message translates to:
  /// **'Notice from a script on {device}'**
  String noticeCover(String device);

  /// Switch on a device's page. Off by default.
  ///
  /// In en, this message translates to:
  /// **'Let scripts on {device} show notices here'**
  String permissionLabel(String device);

  /// No description provided for @permissionDetail.
  ///
  /// In en, this message translates to:
  /// **'For ferret-cli notify. Off until you turn it on.'**
  String get permissionDetail;

  /// No description provided for @settingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Scripts on this computer can follow what Ferret does with ferret-cli watch, and react to it with hooks: an executable named after an event, such as device.connected, in the folder below.'**
  String get settingsIntro;

  /// No description provided for @hooksFolder.
  ///
  /// In en, this message translates to:
  /// **'Hooks folder'**
  String get hooksFolder;

  /// No description provided for @hooksNone.
  ///
  /// In en, this message translates to:
  /// **'No hooks yet.'**
  String get hooksNone;

  /// The list of events that have a hook script, such as 'device.connected, battery'.
  ///
  /// In en, this message translates to:
  /// **'Hooks that run: {events}'**
  String hooksActive(String events);

  /// No description provided for @hooksPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Hooks never get copied text or notification text, and get no names while previews from that device are off.'**
  String get hooksPrivacy;

  /// No description provided for @copyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get copyPath;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// A Tasker or Shortcuts request failed. source is Tasker or Shortcuts.
  ///
  /// In en, this message translates to:
  /// **'{source} couldn\'t do that'**
  String failureTitle(String source);

  /// No description provided for @failureNotConnected.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t connected right now.'**
  String failureNotConnected(String device);

  /// No description provided for @failureUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'No paired device is called {device}.'**
  String failureUnknownDevice(String device);

  /// No description provided for @failureAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'Several devices fit {device}. Use more of its name.'**
  String failureAmbiguous(String device);

  /// No description provided for @failureNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'{device} doesn\'t take notices from scripts here yet.'**
  String failureNotAllowed(String device);

  /// No description provided for @failureUnknownAction.
  ///
  /// In en, this message translates to:
  /// **'{device} has no action by that name.'**
  String failureUnknownAction(String device);

  /// No description provided for @failureOther.
  ///
  /// In en, this message translates to:
  /// **'It didn\'t work. Check the action\'s settings.'**
  String get failureOther;
}

class _ScriptingLocalizationsDelegate
    extends LocalizationsDelegate<ScriptingLocalizations> {
  const _ScriptingLocalizationsDelegate();

  @override
  Future<ScriptingLocalizations> load(Locale locale) {
    return SynchronousFuture<ScriptingLocalizations>(
      lookupScriptingLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_ScriptingLocalizationsDelegate old) => false;
}

ScriptingLocalizations lookupScriptingLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ScriptingLocalizationsEn();
    case 'vi':
      return ScriptingLocalizationsVi();
  }

  throw FlutterError(
    'ScriptingLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
