import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'clipboard_localizations_en.dart';
import 'clipboard_localizations_vi.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get title;

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

  /// No description provided for @sentWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a device to connect'**
  String get sentWaiting;

  /// No description provided for @sentWhenBack.
  ///
  /// In en, this message translates to:
  /// **'Sent to {devices} when it came back'**
  String sentWhenBack(String devices);

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
  /// **'From {device}, not on this clipboard yet. Tap Copy.'**
  String writeFailed(String device);

  /// No description provided for @activityCopiedOn.
  ///
  /// In en, this message translates to:
  /// **'Copied on {device}'**
  String activityCopiedOn(String device);

  /// No description provided for @activityNotSent.
  ///
  /// In en, this message translates to:
  /// **'Clipboard not sent'**
  String get activityNotSent;

  /// No description provided for @activityQuote.
  ///
  /// In en, this message translates to:
  /// **'“{text}”'**
  String activityQuote(String text);

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

  /// No description provided for @offerBackgroundSend.
  ///
  /// In en, this message translates to:
  /// **'Send what you copy on its own, even in the background.'**
  String get offerBackgroundSend;

  /// No description provided for @offerTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get offerTurnOn;

  /// Do more offer on Android 13+: add the Quick Settings tile that sends the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Send your clipboard in one tap from the Ferret tile in Quick Settings.'**
  String get offerTile;

  /// No description provided for @offerAddTile.
  ///
  /// In en, this message translates to:
  /// **'Add tile'**
  String get offerAddTile;

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
  /// **'Not sent: the app you copied from marked it as private. Turn on Include passwords in Settings → Clipboard to send these.'**
  String get resultSensitive;

  /// No description provided for @resultImagesOff.
  ///
  /// In en, this message translates to:
  /// **'Not sent: images are off. Turn on Images in Settings → Clipboard to send them.'**
  String get resultImagesOff;

  /// No description provided for @resultTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Not sent: it\'s bigger than the size limit.'**
  String get resultTooLarge;

  /// No description provided for @resultNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No device is connected. Open Ferret on your other device, on the same Wi-Fi.'**
  String get resultNoDevices;

  /// No description provided for @resultFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach your devices. Check they\'re on the same Wi-Fi, then try again.'**
  String get resultFailed;

  /// No description provided for @summarySyncs.
  ///
  /// In en, this message translates to:
  /// **'Syncs by itself'**
  String get summarySyncs;

  /// No description provided for @summarySends.
  ///
  /// In en, this message translates to:
  /// **'Sends by itself'**
  String get summarySends;

  /// No description provided for @summaryByHand.
  ///
  /// In en, this message translates to:
  /// **'Send by hand'**
  String get summaryByHand;

  /// No description provided for @healthSyncs.
  ///
  /// In en, this message translates to:
  /// **'Syncs by itself'**
  String get healthSyncs;

  /// No description provided for @healthByHand.
  ///
  /// In en, this message translates to:
  /// **'Send by hand'**
  String get healthByHand;

  /// No description provided for @healthOnlyHereSends.
  ///
  /// In en, this message translates to:
  /// **'Sends by itself. {name} sends by hand.'**
  String healthOnlyHereSends(String name);

  /// No description provided for @healthOnlyTheySend.
  ///
  /// In en, this message translates to:
  /// **'{name} sends by itself. Send by hand from here.'**
  String healthOnlyTheySend(String name);

  /// No description provided for @healthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Needs a Ferret update on {name}'**
  String healthUnsupported(String name);

  /// No description provided for @settingsBackgroundSendLost.
  ///
  /// In en, this message translates to:
  /// **'Background sending stopped: Shizuku or root is no longer on. Set it up again in Settings → Control → Power-ups.'**
  String get settingsBackgroundSendLost;

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
  /// **'{here, select, tablet{This tablet} other{This phone}} only allows it for copies made inside Ferret. Use Send clipboard for the rest.'**
  String settingsAutoSendBodyManual(String here);

  /// No description provided for @settingsBackgroundSend.
  ///
  /// In en, this message translates to:
  /// **'Send automatically in the background'**
  String get settingsBackgroundSend;

  /// No description provided for @settingsBackgroundSendBody.
  ///
  /// In en, this message translates to:
  /// **'Send text you copy in any app, also while Ferret is closed. Uses your power-up (Shizuku or root). Images still need Send clipboard.'**
  String get settingsBackgroundSendBody;

  /// No description provided for @settingsWhyManual.
  ///
  /// In en, this message translates to:
  /// **'Why Send clipboard?'**
  String get settingsWhyManual;

  /// No description provided for @settingsWhyManualAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android doesn\'t let apps read your clipboard in the background. Copy, then tap Send clipboard in Ferret, in its notification or in the Quick Settings tile.'**
  String get settingsWhyManualAndroid;

  /// No description provided for @settingsWhyManualIos.
  ///
  /// In en, this message translates to:
  /// **'iPhone only lets apps read your clipboard when you ask. Copy, then tap Send clipboard.'**
  String get settingsWhyManualIos;

  /// No description provided for @settingsBackgroundSendLocked.
  ///
  /// In en, this message translates to:
  /// **'Needs Shizuku or root. Set one up in Settings → Control → Power-ups.'**
  String get settingsBackgroundSendLocked;

  /// No description provided for @settingsAutoReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive automatically'**
  String get settingsAutoReceive;

  /// No description provided for @settingsAutoReceiveBody.
  ///
  /// In en, this message translates to:
  /// **'Put what your devices send straight on this clipboard. When off, tap Copy next to what arrived.'**
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
  /// **'Include passwords'**
  String get settingsSensitive;

  /// No description provided for @settingsSensitiveBody.
  ///
  /// In en, this message translates to:
  /// **'Off by default: copied passwords are skipped. On, they sync and are wiped after {minutes, plural, other{{minutes} min}}.'**
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

  /// No description provided for @settingsWhyManualWayland.
  ///
  /// In en, this message translates to:
  /// **'On Wayland, only the window in front hears about a new copy. GNOME has no way around that, so Ferret sends what you copied once its window is in front again, or when you pick Send clipboard on a device or in the tray. On KDE Plasma and Sway, install wl-clipboard (2.3 or newer on Plasma 6.5 and later) and Ferret watches by itself.'**
  String get settingsWhyManualWayland;

  /// No description provided for @settingsAutoSendBodyWayland.
  ///
  /// In en, this message translates to:
  /// **'On this desktop, copies go out while Ferret\'s window is in front. Use Send clipboard for the rest.'**
  String get settingsAutoSendBodyWayland;

  /// No description provided for @recentClips.
  ///
  /// In en, this message translates to:
  /// **'Recent clips'**
  String get recentClips;

  /// No description provided for @recentClipsMenu.
  ///
  /// In en, this message translates to:
  /// **'Recent clips…'**
  String get recentClipsMenu;

  /// No description provided for @recentClipsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing copied yet. What you copy here or on your devices shows up here.'**
  String get recentClipsEmpty;

  /// No description provided for @recentClipsNote.
  ///
  /// In en, this message translates to:
  /// **'The last 20, kept in memory until Ferret quits. Private items never show up here.'**
  String get recentClipsNote;

  /// No description provided for @recentClipsKeys.
  ///
  /// In en, this message translates to:
  /// **'Open this from any app with {keys}.'**
  String recentClipsKeys(String keys);

  /// No description provided for @recentFrom.
  ///
  /// In en, this message translates to:
  /// **'From {device}'**
  String recentFrom(String device);

  /// No description provided for @recentCopiedHere.
  ///
  /// In en, this message translates to:
  /// **'Copied here'**
  String get recentCopiedHere;

  /// No description provided for @recentHidden.
  ///
  /// In en, this message translates to:
  /// **'Previews from this device are hidden here. Copy still works.'**
  String get recentHidden;

  /// No description provided for @recentClipsDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag one into any app to drop it there.'**
  String get recentClipsDrag;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_ClipboardLocalizationsDelegate old) => false;
}

ClipboardLocalizations lookupClipboardLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ClipboardLocalizationsEn();
    case 'vi':
      return ClipboardLocalizationsVi();
  }

  throw FlutterError(
    'ClipboardLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
