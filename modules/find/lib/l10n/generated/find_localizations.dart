import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'find_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of FindLocalizations
/// returned by `FindLocalizations.of(context)`.
///
/// Applications need to include `FindLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/find_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: FindLocalizations.localizationsDelegates,
///   supportedLocales: FindLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the FindLocalizations.supportedLocales
/// property.
abstract class FindLocalizations {
  FindLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static FindLocalizations of(BuildContext context) {
    return Localizations.of<FindLocalizations>(context, FindLocalizations)!;
  }

  static const LocalizationsDelegate<FindLocalizations> delegate =
      _FindLocalizationsDelegate();

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
  /// **'Find'**
  String get title;

  /// Device action that makes another device ring.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get ring;

  /// Stops the ring on the ringing device.
  ///
  /// In en, this message translates to:
  /// **'Found it'**
  String get foundIt;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @ringAgain.
  ///
  /// In en, this message translates to:
  /// **'Ring again'**
  String get ringAgain;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Title of the ringing notice and screen.
  ///
  /// In en, this message translates to:
  /// **'Ferret is ringing'**
  String get ringingTitle;

  /// No description provided for @ringingBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is looking for this device.'**
  String ringingBody(String name);

  /// No description provided for @ringingMuted.
  ///
  /// In en, this message translates to:
  /// **'This device is on silent, so it only vibrates.'**
  String get ringingMuted;

  /// No description provided for @ringingHere.
  ///
  /// In en, this message translates to:
  /// **'This device is ringing'**
  String get ringingHere;

  /// No description provided for @findDevice.
  ///
  /// In en, this message translates to:
  /// **'Find {name}'**
  String findDevice(String name);

  /// No description provided for @outgoingRequesting.
  ///
  /// In en, this message translates to:
  /// **'Asking {name} to ring…'**
  String outgoingRequesting(String name);

  /// No description provided for @outgoingRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing {name}…'**
  String outgoingRinging(String name);

  /// No description provided for @outgoingRingingDetail.
  ///
  /// In en, this message translates to:
  /// **'It rings for up to 2 minutes, or until someone taps Found it.'**
  String get outgoingRingingDetail;

  /// No description provided for @outgoingRingingMuted.
  ///
  /// In en, this message translates to:
  /// **'{name} is on silent, so it only vibrates. On {name}: turn on Ring on silent in Ferret.'**
  String outgoingRingingMuted(String name);

  /// No description provided for @outgoingFound.
  ///
  /// In en, this message translates to:
  /// **'{name} was found.'**
  String outgoingFound(String name);

  /// No description provided for @outgoingTimedOut.
  ///
  /// In en, this message translates to:
  /// **'{name} stopped ringing on its own.'**
  String outgoingTimedOut(String name);

  /// No description provided for @outgoingStoppedHere.
  ///
  /// In en, this message translates to:
  /// **'Stopped ringing {name}.'**
  String outgoingStoppedHere(String name);

  /// No description provided for @outgoingStoppedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'{name} was stopped from another device.'**
  String outgoingStoppedElsewhere(String name);

  /// No description provided for @outgoingNoSound.
  ///
  /// In en, this message translates to:
  /// **'{name} couldn\'t play a sound.'**
  String outgoingNoSound(String name);

  /// No description provided for @outgoingNoSoundDetail.
  ///
  /// In en, this message translates to:
  /// **'On {name}: check that the sound works. Then ring again.'**
  String outgoingNoSoundDetail(String name);

  /// No description provided for @outgoingUnreachable.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t answer.'**
  String outgoingUnreachable(String name);

  /// No description provided for @outgoingUnreachableDetail.
  ///
  /// In en, this message translates to:
  /// **'Make sure {name} is on and on the same Wi-Fi, then ring again.'**
  String outgoingUnreachableDetail(String name);

  /// No description provided for @outgoingNotSupported.
  ///
  /// In en, this message translates to:
  /// **'{name} can\'t ring yet.'**
  String outgoingNotSupported(String name);

  /// No description provided for @outgoingNotSupportedDetail.
  ///
  /// In en, this message translates to:
  /// **'Update Ferret on {name}, then ring again.'**
  String outgoingNotSupportedDetail(String name);

  /// No description provided for @outgoingLostConnection.
  ///
  /// In en, this message translates to:
  /// **'Lost the connection to {name}.'**
  String outgoingLostConnection(String name);

  /// No description provided for @outgoingLostConnectionDetail.
  ///
  /// In en, this message translates to:
  /// **'{name} keeps ringing for up to 2 minutes, or until someone taps Found it there.'**
  String outgoingLostConnectionDetail(String name);

  /// No description provided for @settingsRingOnSilent.
  ///
  /// In en, this message translates to:
  /// **'Ring on silent'**
  String get settingsRingOnSilent;

  /// No description provided for @settingsRingOnSilentAndroid.
  ///
  /// In en, this message translates to:
  /// **'Rings at full volume, even on silent or Do Not Disturb. The volume goes back after.'**
  String get settingsRingOnSilentAndroid;

  /// No description provided for @settingsRingOnSilentMac.
  ///
  /// In en, this message translates to:
  /// **'Turns the volume up and unmutes while ringing, then puts it back.'**
  String get settingsRingOnSilentMac;

  /// No description provided for @settingsFlashTorch.
  ///
  /// In en, this message translates to:
  /// **'Flash the torch'**
  String get settingsFlashTorch;

  /// No description provided for @settingsFlashTorchBody.
  ///
  /// In en, this message translates to:
  /// **'Blinks the flashlight while ringing, so you spot it in the dark.'**
  String get settingsFlashTorchBody;

  /// No description provided for @settingsDndOn.
  ///
  /// In en, this message translates to:
  /// **'Rings through Do Not Disturb.'**
  String get settingsDndOn;

  /// No description provided for @settingsDndOff.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb access is off'**
  String get settingsDndOff;

  /// No description provided for @settingsDndHowTo.
  ///
  /// In en, this message translates to:
  /// **'Without it, this phone rings on silent but stays quiet in Do Not Disturb. Tap Allow in Settings, find Ferret in the list and turn it on.'**
  String get settingsDndHowTo;

  /// No description provided for @settingsDndStillOff.
  ///
  /// In en, this message translates to:
  /// **'Still off. Find Ferret in the list, turn it on, then come back.'**
  String get settingsDndStillOff;

  /// No description provided for @settingsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow in Settings'**
  String get settingsAllow;

  /// No description provided for @settingsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Settings. Open Settings, then Notifications, then Do Not Disturb access, and turn Ferret on.'**
  String get settingsOpenFailed;

  /// No description provided for @settingsFullScreenOff.
  ///
  /// In en, this message translates to:
  /// **'The ringing screen can\'t show over the lock screen'**
  String get settingsFullScreenOff;

  /// No description provided for @settingsFullScreenHowTo.
  ///
  /// In en, this message translates to:
  /// **'You still hear it and get a notification. Allow full-screen notifications to see Found it right away.'**
  String get settingsFullScreenHowTo;

  /// No description provided for @settingsLimitIos.
  ///
  /// In en, this message translates to:
  /// **'This iPhone rings, even on silent, only while Ferret is open. iOS stops apps soon after they leave the screen.'**
  String get settingsLimitIos;

  /// No description provided for @settingsLimitDesktop.
  ///
  /// In en, this message translates to:
  /// **'Rings at the current volume. Keep the sound on to hear it.'**
  String get settingsLimitDesktop;

  /// No description provided for @settingsLimitNoPlayer.
  ///
  /// In en, this message translates to:
  /// **'No sound player found, so this computer can\'t ring. Install pw-play, paplay or aplay.'**
  String get settingsLimitNoPlayer;

  /// No description provided for @settingsTestRing.
  ///
  /// In en, this message translates to:
  /// **'Test ring'**
  String get settingsTestRing;

  /// No description provided for @settingsTestRingBody.
  ///
  /// In en, this message translates to:
  /// **'Rings this device for 5 seconds.'**
  String get settingsTestRingBody;

  /// No description provided for @healthLoud.
  ///
  /// In en, this message translates to:
  /// **'Rings, even on silent'**
  String healthLoud(String name);

  /// No description provided for @healthFollowsSilent.
  ///
  /// In en, this message translates to:
  /// **'Rings, quiet on silent'**
  String healthFollowsSilent(String name);

  /// No description provided for @healthNeedsAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Rings only while Ferret is open on {name}'**
  String healthNeedsAppOpen(String name);

  /// No description provided for @healthNeedsPermission.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb keeps {name} quiet'**
  String healthNeedsPermission(String name);

  /// No description provided for @healthNotAnswering.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t answer the last ring'**
  String healthNotAnswering(String name);

  /// No description provided for @healthNoSound.
  ///
  /// In en, this message translates to:
  /// **'{name} couldn\'t play a sound last time'**
  String healthNoSound(String name);

  /// No description provided for @healthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Needs a Ferret update on {name}'**
  String healthUnsupported(String name);
}

class _FindLocalizationsDelegate
    extends LocalizationsDelegate<FindLocalizations> {
  const _FindLocalizationsDelegate();

  @override
  Future<FindLocalizations> load(Locale locale) {
    return SynchronousFuture<FindLocalizations>(
      lookupFindLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_FindLocalizationsDelegate old) => false;
}

FindLocalizations lookupFindLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return FindLocalizationsEn();
  }

  throw FlutterError(
    'FindLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
