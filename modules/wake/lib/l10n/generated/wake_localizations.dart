import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'wake_localizations_en.dart';
import 'wake_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of WakeLocalizations
/// returned by `WakeLocalizations.of(context)`.
///
/// Applications need to include `WakeLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/wake_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: WakeLocalizations.localizationsDelegates,
///   supportedLocales: WakeLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the WakeLocalizations.supportedLocales
/// property.
abstract class WakeLocalizations {
  WakeLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static WakeLocalizations of(BuildContext context) {
    return Localizations.of<WakeLocalizations>(context, WakeLocalizations)!;
  }

  static const LocalizationsDelegate<WakeLocalizations> delegate =
      _WakeLocalizationsDelegate();

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

  /// Name of the feature that wakes a sleeping computer over the network.
  ///
  /// In en, this message translates to:
  /// **'Wake-on-LAN'**
  String get title;

  /// Action on an offline computer: wakes it from sleep.
  ///
  /// In en, this message translates to:
  /// **'Wake'**
  String get wake;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Status line while waiting for a woken computer to connect.
  ///
  /// In en, this message translates to:
  /// **'Waking {name}… (up to a minute)'**
  String waking(String name);

  /// Status line when a computer didn't connect within about 90 seconds of the wake signal.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t wake'**
  String get didntWake;

  /// Status line when no device could send the magic packet.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the wake signal'**
  String get couldntSend;

  /// No description provided for @howToTurnOn.
  ///
  /// In en, this message translates to:
  /// **'How to turn on Wake-on-LAN'**
  String get howToTurnOn;

  /// No description provided for @healthReady.
  ///
  /// In en, this message translates to:
  /// **'Can wake it from sleep'**
  String get healthReady;

  /// No description provided for @healthWiredUnknown.
  ///
  /// In en, this message translates to:
  /// **'Can try to wake it over its cable'**
  String get healthWiredUnknown;

  /// No description provided for @healthWiredOff.
  ///
  /// In en, this message translates to:
  /// **'Wake-on-LAN is off on {name}'**
  String healthWiredOff(String name);

  /// No description provided for @healthWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only: it may not wake'**
  String get healthWifiOnly;

  /// No description provided for @healthHelp.
  ///
  /// In en, this message translates to:
  /// **'On {name}: Ferret → Settings → Control → Wake-on-LAN shows what to turn on.'**
  String healthHelp(String name);

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Wake-on-LAN'**
  String get helpTitle;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Wake-on-LAN starts a sleeping computer when another device sends it a “magic packet” over the network. Ferret sends one when you tap Wake. The computer has to allow it first, once.'**
  String get helpIntro;

  /// No description provided for @helpToldTitle.
  ///
  /// In en, this message translates to:
  /// **'What {name} told Ferret'**
  String helpToldTitle(String name);

  /// No description provided for @helpThisComputer.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get helpThisComputer;

  /// No description provided for @cardWiredOn.
  ///
  /// In en, this message translates to:
  /// **'Cable · Wake-on-LAN is on'**
  String get cardWiredOn;

  /// No description provided for @cardWiredOff.
  ///
  /// In en, this message translates to:
  /// **'Cable · Wake-on-LAN is off'**
  String get cardWiredOff;

  /// No description provided for @cardWiredUnknown.
  ///
  /// In en, this message translates to:
  /// **'Cable · can\'t tell whether Wake-on-LAN is on'**
  String get cardWiredUnknown;

  /// No description provided for @cardWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi · few computers wake over Wi-Fi'**
  String get cardWifi;

  /// No description provided for @cardNone.
  ///
  /// In en, this message translates to:
  /// **'No network card to wake it by yet. Open Ferret on it once.'**
  String get cardNone;

  /// No description provided for @helpBestTitle.
  ///
  /// In en, this message translates to:
  /// **'What works'**
  String get helpBestTitle;

  /// No description provided for @helpBest.
  ///
  /// In en, this message translates to:
  /// **'A cable to the router, asleep rather than shut down, and another of your devices on the same network. Over Wi-Fi most computers don\'t wake at all: a cable makes it reliable.'**
  String get helpBest;

  /// No description provided for @helpMacTitle.
  ///
  /// In en, this message translates to:
  /// **'Mac'**
  String get helpMacTitle;

  /// No description provided for @helpMac.
  ///
  /// In en, this message translates to:
  /// **'System Settings → Battery → Options → Wake for network access (on a desktop Mac: System Settings → Energy). A Mac on Wi-Fi wakes only through a Bonjour Sleep Proxy, such as an Apple TV or HomePod on the same network.'**
  String get helpMac;

  /// No description provided for @helpWindowsTitle.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get helpWindowsTitle;

  /// No description provided for @helpWindows.
  ///
  /// In en, this message translates to:
  /// **'1. Device Manager → Network adapters → your Ethernet card → Properties.\n2. Power Management: turn on “Allow this device to wake the computer” and “Only allow a magic packet to wake the computer”.\n3. Advanced: set “Wake on Magic Packet” to Enabled.\n4. To wake it from shut down, turn off Fast startup: Control Panel → Power Options → Choose what the power buttons do.'**
  String get helpWindows;

  /// No description provided for @helpLinuxTitle.
  ///
  /// In en, this message translates to:
  /// **'Linux'**
  String get helpLinuxTitle;

  /// No description provided for @helpLinux.
  ///
  /// In en, this message translates to:
  /// **'Turn it on for the card: sudo ethtool -s enp3s0 wol g (use your card\'s name from “ip link”).\nKeep it after a restart: nmcli connection modify \"Wired connection 1\" 802-3-ethernet.wake-on-lan magic.'**
  String get helpLinux;

  /// No description provided for @helpFirmwareTitle.
  ///
  /// In en, this message translates to:
  /// **'BIOS or UEFI (Windows and Linux PCs)'**
  String get helpFirmwareTitle;

  /// No description provided for @helpFirmware.
  ///
  /// In en, this message translates to:
  /// **'Press F2, Del or F12 while the PC starts. Turn on “Wake on LAN”, “Power On by PCI-E” or a setting like it, and turn off “ErP” or “Deep Sleep”, which cut power to the network card.'**
  String get helpFirmware;

  /// No description provided for @helpIphoneTitle.
  ///
  /// In en, this message translates to:
  /// **'From an iPhone'**
  String get helpIphoneTitle;

  /// No description provided for @helpIphone.
  ///
  /// In en, this message translates to:
  /// **'iOS doesn\'t let apps broadcast on the network, so an iPhone can\'t send the magic packet by itself. Ferret asks another of your devices that is on, such as a Mac, a PC or ferret-cli on a home server, to send it for you.'**
  String get helpIphone;

  /// No description provided for @settingsShare.
  ///
  /// In en, this message translates to:
  /// **'Let my devices wake this computer'**
  String get settingsShare;

  /// No description provided for @settingsShareBody.
  ///
  /// In en, this message translates to:
  /// **'Tells your paired devices, and only them, this computer\'s network card address (MAC), so they can wake it.'**
  String get settingsShareBody;

  /// No description provided for @settingsRelay.
  ///
  /// In en, this message translates to:
  /// **'Wake computers for my phones'**
  String get settingsRelay;

  /// No description provided for @settingsRelayBody.
  ///
  /// In en, this message translates to:
  /// **'When one of your phones asks, this computer sends the wake signal to another of your computers on this network.'**
  String get settingsRelayBody;

  /// No description provided for @settingsReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get settingsReady;

  /// No description provided for @settingsNotReady.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsNotReady;

  /// No description provided for @settingsWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get settingsWifiOnly;
}

class _WakeLocalizationsDelegate
    extends LocalizationsDelegate<WakeLocalizations> {
  const _WakeLocalizationsDelegate();

  @override
  Future<WakeLocalizations> load(Locale locale) {
    return SynchronousFuture<WakeLocalizations>(
      lookupWakeLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_WakeLocalizationsDelegate old) => false;
}

WakeLocalizations lookupWakeLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return WakeLocalizationsEn();
    case 'vi':
      return WakeLocalizationsVi();
  }

  throw FlutterError(
    'WakeLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
