import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'media_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of MediaLocalizations
/// returned by `MediaLocalizations.of(context)`.
///
/// Applications need to include `MediaLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/media_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: MediaLocalizations.localizationsDelegates,
///   supportedLocales: MediaLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the MediaLocalizations.supportedLocales
/// property.
abstract class MediaLocalizations {
  MediaLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static MediaLocalizations of(BuildContext context) {
    return Localizations.of<MediaLocalizations>(context, MediaLocalizations)!;
  }

  static const LocalizationsDelegate<MediaLocalizations> delegate =
      _MediaLocalizationsDelegate();

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
  /// **'Media'**
  String get title;

  /// No description provided for @nowPlayingOn.
  ///
  /// In en, this message translates to:
  /// **'Now playing on {device}'**
  String nowPlayingOn(String device);

  /// No description provided for @pausedOn.
  ///
  /// In en, this message translates to:
  /// **'Paused on {device}'**
  String pausedOn(String device);

  /// No description provided for @playerOn.
  ///
  /// In en, this message translates to:
  /// **'{app} on {device}'**
  String playerOn(String app, String device);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @continueHere.
  ///
  /// In en, this message translates to:
  /// **'Continue here'**
  String get continueHere;

  /// No description provided for @continueOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get continueOpening;

  /// No description provided for @continueFromStart.
  ///
  /// In en, this message translates to:
  /// **'Opens from the start'**
  String get continueFromStart;

  /// No description provided for @continueNoLink.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be opened here. {app} didn\'t share a link to it.'**
  String continueNoLink(String app);

  /// No description provided for @continueOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'No app here could open it. It keeps playing on {device}.'**
  String continueOpenFailed(String device);

  /// No description provided for @playerGone.
  ///
  /// In en, this message translates to:
  /// **'That player closed on {device}.'**
  String playerGone(String device);

  /// No description provided for @deviceUnreachable.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer. Check that Ferret is running there, then try again.'**
  String deviceUnreachable(String device);

  /// No description provided for @deviceNotSharing.
  ///
  /// In en, this message translates to:
  /// **'{device} stopped sharing its media. Turn on Share my media there.'**
  String deviceNotSharing(String device);

  /// No description provided for @commandUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This player can\'t do that.'**
  String get commandUnsupported;

  /// No description provided for @commandFailed.
  ///
  /// In en, this message translates to:
  /// **'The player on {device} didn\'t respond. Try again.'**
  String commandFailed(String device);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @settingsShare.
  ///
  /// In en, this message translates to:
  /// **'Share my media'**
  String get settingsShare;

  /// No description provided for @settingsShareBody.
  ///
  /// In en, this message translates to:
  /// **'Your other devices see what plays here and can control it.'**
  String get settingsShareBody;

  /// No description provided for @settingsShowRemote.
  ///
  /// In en, this message translates to:
  /// **'Show media from other devices'**
  String get settingsShowRemote;

  /// No description provided for @settingsShowRemoteBody.
  ///
  /// In en, this message translates to:
  /// **'What plays on your other devices, with controls and Continue here.'**
  String get settingsShowRemoteBody;

  /// No description provided for @accessAndroid.
  ///
  /// In en, this message translates to:
  /// **'Ferret needs Notification access to see what plays on this phone. It only reads media controls here.'**
  String get accessAndroid;

  /// No description provided for @accessMacos.
  ///
  /// In en, this message translates to:
  /// **'macOS asks once to let Ferret control Music and Spotify.'**
  String get accessMacos;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Ferret can\'t control Music or Spotify yet. Allow it in System Settings, Privacy & Security, Automation.'**
  String get accessDenied;

  /// No description provided for @accessAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get accessAllow;

  /// No description provided for @accessOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get accessOpenSettings;

  /// No description provided for @accessCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get accessCheckAgain;

  /// No description provided for @limitMacos.
  ///
  /// In en, this message translates to:
  /// **'On a Mac, Ferret sees Music and Spotify. macOS doesn\'t let apps see other players.'**
  String get limitMacos;

  /// No description provided for @limitIos.
  ///
  /// In en, this message translates to:
  /// **'iPhone doesn\'t let apps see what other apps play. You can still see and control media on your other devices.'**
  String get limitIos;

  /// No description provided for @limitWindows.
  ///
  /// In en, this message translates to:
  /// **'Ferret sees players that show in the Windows media controls. Volume stays on this PC.'**
  String get limitWindows;

  /// No description provided for @limitLinux.
  ///
  /// In en, this message translates to:
  /// **'Ferret sees players that support MPRIS, which most Linux players do.'**
  String get limitLinux;
}

class _MediaLocalizationsDelegate
    extends LocalizationsDelegate<MediaLocalizations> {
  const _MediaLocalizationsDelegate();

  @override
  Future<MediaLocalizations> load(Locale locale) {
    return SynchronousFuture<MediaLocalizations>(
      lookupMediaLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_MediaLocalizationsDelegate old) => false;
}

MediaLocalizations lookupMediaLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return MediaLocalizationsEn();
  }

  throw FlutterError(
    'MediaLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
