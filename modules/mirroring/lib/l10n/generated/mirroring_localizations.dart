import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'mirroring_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of MirroringLocalizations
/// returned by `MirroringLocalizations.of(context)`.
///
/// Applications need to include `MirroringLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/mirroring_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: MirroringLocalizations.localizationsDelegates,
///   supportedLocales: MirroringLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the MirroringLocalizations.supportedLocales
/// property.
abstract class MirroringLocalizations {
  MirroringLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static MirroringLocalizations of(BuildContext context) {
    return Localizations.of<MirroringLocalizations>(
      context,
      MirroringLocalizations,
    )!;
  }

  static const LocalizationsDelegate<MirroringLocalizations> delegate =
      _MirroringLocalizationsDelegate();

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
  /// **'Screen mirroring'**
  String get title;

  /// No description provided for @showScreen.
  ///
  /// In en, this message translates to:
  /// **'Show screen'**
  String get showScreen;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @fit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get fit;

  /// No description provided for @actualSize.
  ///
  /// In en, this message translates to:
  /// **'1:1'**
  String get actualSize;

  /// No description provided for @fitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fit the picture to the window'**
  String get fitTooltip;

  /// No description provided for @actualSizeTooltip.
  ///
  /// In en, this message translates to:
  /// **'One phone pixel per screen pixel'**
  String get actualSizeTooltip;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// No description provided for @exitFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get exitFullScreen;

  /// No description provided for @requestingTitle.
  ///
  /// In en, this message translates to:
  /// **'Asking {device}…'**
  String requestingTitle(String device);

  /// No description provided for @requestingBody.
  ///
  /// In en, this message translates to:
  /// **'This takes a moment.'**
  String get requestingBody;

  /// No description provided for @waitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Answer on {device}'**
  String waitingTitle(String device);

  /// No description provided for @waitingBody.
  ///
  /// In en, this message translates to:
  /// **'Android asks whether to share the screen. Tap Start on {device}. If the phone shows nothing, open the notice from Ferret there.'**
  String waitingBody(String device);

  /// No description provided for @startingTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} said yes'**
  String startingTitle(String device);

  /// No description provided for @startingBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the first picture…'**
  String get startingBody;

  /// No description provided for @screenOffTitle.
  ///
  /// In en, this message translates to:
  /// **'{device}\'s screen is off'**
  String screenOffTitle(String device);

  /// No description provided for @screenOffBody.
  ///
  /// In en, this message translates to:
  /// **'Wake the phone to see it again.'**
  String get screenOffBody;

  /// No description provided for @endDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} said no'**
  String endDeniedTitle(String device);

  /// No description provided for @endDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Someone tapped Cancel on the phone\'s prompt. You can ask again in half a minute.'**
  String get endDeniedBody;

  /// No description provided for @endTimedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody answered on {device}'**
  String endTimedOutTitle(String device);

  /// No description provided for @endTimedOutBody.
  ///
  /// In en, this message translates to:
  /// **'The question stays on the phone for a minute. Wake the phone, then try again.'**
  String get endTimedOutBody;

  /// No description provided for @endBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} is already sharing its screen'**
  String endBusyTitle(String device);

  /// No description provided for @endBusyBody.
  ///
  /// In en, this message translates to:
  /// **'A phone shares its screen with one device at a time. Stop the other one first.'**
  String get endBusyBody;

  /// No description provided for @endUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t share its screen'**
  String endUnsupportedTitle(String device);

  /// No description provided for @endUnsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'Screen mirroring needs an Android phone with Ferret.'**
  String get endUnsupportedBody;

  /// No description provided for @endTurnedOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen mirroring is off on {device}'**
  String endTurnedOffTitle(String device);

  /// No description provided for @endTurnedOffBody.
  ///
  /// In en, this message translates to:
  /// **'Turn it on in Ferret on the phone: Settings, then Screen mirroring.'**
  String get endTurnedOffBody;

  /// No description provided for @endCannotAskTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t show the question'**
  String endCannotAskTitle(String device);

  /// No description provided for @endCannotAskBody.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret on the phone, or allow its notifications, then try again.'**
  String get endCannotAskBody;

  /// No description provided for @endVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} needs a newer Ferret'**
  String endVersionTitle(String device);

  /// No description provided for @endVersionBody.
  ///
  /// In en, this message translates to:
  /// **'Update Ferret on the phone, then try again.'**
  String get endVersionBody;

  /// No description provided for @endNoCodecTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t send a picture this computer can show'**
  String endNoCodecTitle(String device);

  /// No description provided for @endNoCodecBody.
  ///
  /// In en, this message translates to:
  /// **'Update Ferret on both devices, then try again.'**
  String get endNoCodecBody;

  /// No description provided for @endNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t connected'**
  String endNotConnectedTitle(String device);

  /// No description provided for @endNotConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Open Ferret on the phone and check both devices are on the same Wi-Fi.'**
  String get endNotConnectedBody;

  /// No description provided for @endNoAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer'**
  String endNoAnswerTitle(String device);

  /// No description provided for @endNoAnswerBody.
  ///
  /// In en, this message translates to:
  /// **'Check that Ferret is running on the phone, then try again.'**
  String get endNoAnswerBody;

  /// No description provided for @endStoppedHereTitle.
  ///
  /// In en, this message translates to:
  /// **'You stopped mirroring'**
  String get endStoppedHereTitle;

  /// No description provided for @endStoppedHereBody.
  ///
  /// In en, this message translates to:
  /// **'{device} no longer shares its screen.'**
  String endStoppedHereBody(String device);

  /// No description provided for @endStoppedOnPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Stopped on {device}'**
  String endStoppedOnPhoneTitle(String device);

  /// No description provided for @endStoppedOnPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Someone tapped Stop on the phone.'**
  String get endStoppedOnPhoneBody;

  /// No description provided for @endSystemEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} stopped sharing'**
  String endSystemEndedTitle(String device);

  /// No description provided for @endSystemEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Android ends screen sharing when the phone locks, or when its owner stops it from the status bar.'**
  String get endSystemEndedBody;

  /// No description provided for @endLostConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Lost the connection to {device}'**
  String endLostConnectionTitle(String device);

  /// No description provided for @endLostConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret reconnects on its own. Try again once the phone is back.'**
  String get endLostConnectionBody;

  /// No description provided for @endFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Mirroring stopped working'**
  String get endFailedTitle;

  /// No description provided for @endFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Capturing the screen failed on {device}. Try again.'**
  String endFailedBody(String device);

  /// No description provided for @endDecoderFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'This computer couldn\'t show the picture'**
  String get endDecoderFailedTitle;

  /// No description provided for @endDecoderFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Decoding the video failed here. Try again.'**
  String get endDecoderFailedBody;

  /// No description provided for @statusPicture.
  ///
  /// In en, this message translates to:
  /// **'{codec} · {width}×{height} · {fps} fps'**
  String statusPicture(String codec, int width, int height, int fps);

  /// No description provided for @statusLatency.
  ///
  /// In en, this message translates to:
  /// **'{milliseconds} ms'**
  String statusLatency(int milliseconds);

  /// No description provided for @statusBitrate.
  ///
  /// In en, this message translates to:
  /// **'{megabits} Mbps'**
  String statusBitrate(String megabits);

  /// No description provided for @statusDropped.
  ///
  /// In en, this message translates to:
  /// **'{count} dropped'**
  String statusDropped(int count);

  /// No description provided for @codecH264.
  ///
  /// In en, this message translates to:
  /// **'H.264'**
  String get codecH264;

  /// No description provided for @codecJpeg.
  ///
  /// In en, this message translates to:
  /// **'JPEG'**
  String get codecJpeg;

  /// No description provided for @viewingTitle.
  ///
  /// In en, this message translates to:
  /// **'Showing {device}\'s screen'**
  String viewingTitle(String device);

  /// No description provided for @viewingWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {device}'**
  String viewingWaitingTitle(String device);

  /// No description provided for @viewingWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Answer the prompt on the phone.'**
  String get viewingWaitingBody;

  /// No description provided for @sinceTime.
  ///
  /// In en, this message translates to:
  /// **'Since {time}'**
  String sinceTime(String time);

  /// No description provided for @sharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing screen with {device}'**
  String sharingTitle(String device);

  /// No description provided for @sharingBody.
  ///
  /// In en, this message translates to:
  /// **'Everything on this screen is visible there. Since {time}.'**
  String sharingBody(String time);

  /// No description provided for @askingTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to see this screen'**
  String askingTitle(String device);

  /// No description provided for @askingBody.
  ///
  /// In en, this message translates to:
  /// **'Answer Android\'s prompt. If you don\'t see it, tap the notice from Ferret.'**
  String get askingBody;

  /// No description provided for @auditShared.
  ///
  /// In en, this message translates to:
  /// **'{device} viewed your screen for {duration} at {time}'**
  String auditShared(String device, String duration, String time);

  /// No description provided for @auditViewed.
  ///
  /// In en, this message translates to:
  /// **'You viewed {device}\'s screen for {duration} at {time}'**
  String auditViewed(String device, String duration, String time);

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{1 s} other{{seconds} s}}'**
  String durationSeconds(int seconds);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 min} other{{minutes} min}}'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHours(int hours, int minutes);

  /// No description provided for @noticeAskBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to answer'**
  String get noticeAskBody;

  /// No description provided for @noticeAskChannel.
  ///
  /// In en, this message translates to:
  /// **'Screen sharing requests'**
  String get noticeAskChannel;

  /// No description provided for @noticeSharingBody.
  ///
  /// In en, this message translates to:
  /// **'Everything on this screen is visible there'**
  String get noticeSharingBody;

  /// No description provided for @noticeSharingChannel.
  ///
  /// In en, this message translates to:
  /// **'Screen sharing'**
  String get noticeSharingChannel;

  /// No description provided for @settingsAllow.
  ///
  /// In en, this message translates to:
  /// **'Let my computers ask to see this screen'**
  String get settingsAllow;

  /// No description provided for @settingsAllowBody.
  ///
  /// In en, this message translates to:
  /// **'Android asks you every time. Nothing is shared before you say yes.'**
  String get settingsAllowBody;

  /// No description provided for @settingsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This phone can\'t capture its screen'**
  String get settingsUnsupported;

  /// No description provided for @settingsScreenOffNote.
  ///
  /// In en, this message translates to:
  /// **'Turning the phone\'s screen off while it is mirrored needs root, so Ferret doesn\'t offer it.'**
  String get settingsScreenOffNote;

  /// No description provided for @settingsViewerHint.
  ///
  /// In en, this message translates to:
  /// **'Open a connected Android phone and choose Show screen. The phone asks its owner every time.'**
  String get settingsViewerHint;

  /// No description provided for @settingsHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get settingsHistoryTitle;

  /// No description provided for @settingsHistoryEmptyShared.
  ///
  /// In en, this message translates to:
  /// **'Nobody has seen this screen yet.'**
  String get settingsHistoryEmptyShared;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @healthViewing.
  ///
  /// In en, this message translates to:
  /// **'Showing its screen here'**
  String get healthViewing;

  /// No description provided for @healthTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Screen mirroring is off on {device}'**
  String healthTurnedOff(String device);

  /// No description provided for @healthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t share its screen'**
  String healthUnsupported(String device);

  /// No description provided for @healthCannotAsk.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t show the question. Open Ferret on it.'**
  String healthCannotAsk(String device);
}

class _MirroringLocalizationsDelegate
    extends LocalizationsDelegate<MirroringLocalizations> {
  const _MirroringLocalizationsDelegate();

  @override
  Future<MirroringLocalizations> load(Locale locale) {
    return SynchronousFuture<MirroringLocalizations>(
      lookupMirroringLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_MirroringLocalizationsDelegate old) => false;
}

MirroringLocalizations lookupMirroringLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return MirroringLocalizationsEn();
  }

  throw FlutterError(
    'MirroringLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
