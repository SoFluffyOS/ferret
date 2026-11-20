import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'mirroring_localizations_en.dart';
import 'mirroring_localizations_vi.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Name of the screen mirroring feature (card and settings title)
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get title;

  /// No description provided for @showScreen.
  ///
  /// In en, this message translates to:
  /// **'Show screen'**
  String get showScreen;

  /// No description provided for @windowTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} — Screen'**
  String windowTitle(String device);

  /// No description provided for @inWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'{device}\'s screen has its own window'**
  String inWindowTitle(String device);

  /// No description provided for @bringToFront.
  ///
  /// In en, this message translates to:
  /// **'Bring to front'**
  String get bringToFront;

  /// No description provided for @launcherTitle.
  ///
  /// In en, this message translates to:
  /// **'See {device}\'s screen on {here, select, macOS{this Mac} windows{this PC} other{this computer}}'**
  String launcherTitle(String device, String here);

  /// No description provided for @launcherBody.
  ///
  /// In en, this message translates to:
  /// **'{device} asks you every time, unless it is on a cable you allowed.'**
  String launcherBody(String device);

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

  /// No description provided for @waitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Answer on {device}'**
  String waitingTitle(String device);

  /// No description provided for @waitingBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}, choose to share the entire screen, then Start.'**
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
  /// **'Wake {device} to see it again.'**
  String screenOffBody(String device);

  /// No description provided for @endDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} said no'**
  String endDeniedTitle(String device);

  /// No description provided for @endDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Someone tapped Cancel on {device}.'**
  String endDeniedBody(String device);

  /// No description provided for @endTimedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody answered on {device}'**
  String endTimedOutTitle(String device);

  /// No description provided for @endTimedOutBody.
  ///
  /// In en, this message translates to:
  /// **'The question stays on {device} for a minute. Wake {device}, then ask again.'**
  String endTimedOutBody(String device);

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
  /// **'Showing a screen needs an Android phone with Ferret.'**
  String get endUnsupportedBody;

  /// No description provided for @endTurnedOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Screen sharing is off on {device}'**
  String endTurnedOffTitle(String device);

  /// No description provided for @endTurnedOffBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret → Settings → To your computer and turn on Let my computers ask to see this screen. Then open {here, select, macOS{this Mac} windows{this PC} other{this computer}} there and check that it may ask.'**
  String endTurnedOffBody(String device, String here);

  /// No description provided for @endCannotAskTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t show the question'**
  String endCannotAskTitle(String device);

  /// No description provided for @endCannotAskBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret, or allow its notifications. Then ask again.'**
  String endCannotAskBody(String device);

  /// No description provided for @endVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} needs a newer Ferret'**
  String endVersionTitle(String device);

  /// No description provided for @endVersionBody.
  ///
  /// In en, this message translates to:
  /// **'Update Ferret on {device}, then try again.'**
  String endVersionBody(String device);

  /// No description provided for @endNoCodecTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t send a picture {here, select, macOS{this Mac} windows{this PC} other{this computer}} can show'**
  String endNoCodecTitle(String device, String here);

  /// No description provided for @endNoCodecBody.
  ///
  /// In en, this message translates to:
  /// **'Update Ferret on {device} and on {here, select, macOS{this Mac} windows{this PC} other{this computer}}, then try again.'**
  String endNoCodecBody(String device, String here);

  /// No description provided for @endNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t connected'**
  String endNotConnectedTitle(String device);

  /// No description provided for @endNotConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret. Same Wi-Fi as {here, select, macOS{this Mac} windows{this PC} other{this computer}}?'**
  String endNotConnectedBody(String device, String here);

  /// No description provided for @endNoAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} didn\'t answer'**
  String endNoAnswerTitle(String device);

  /// No description provided for @endNoAnswerBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret. Then try again.'**
  String endNoAnswerBody(String device);

  /// No description provided for @endStoppedOnPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Stopped on {device}'**
  String endStoppedOnPhoneTitle(String device);

  /// No description provided for @endStoppedOnPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'Someone tapped Stop on {device}.'**
  String endStoppedOnPhoneBody(String device);

  /// No description provided for @endSystemEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} stopped sharing'**
  String endSystemEndedTitle(String device);

  /// No description provided for @endSystemEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Android stops sharing when {device} locks, or when someone stops it from the status bar. Unlock {device}, then show it again.'**
  String endSystemEndedBody(String device);

  /// No description provided for @endLostConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Lost the connection to {device}'**
  String endLostConnectionTitle(String device);

  /// No description provided for @endLostConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'Check that {device} is on, and on the same Wi-Fi as {here, select, macOS{this Mac} windows{this PC} other{this computer}}.'**
  String endLostConnectionBody(String device, String here);

  /// No description provided for @endFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'The picture stopped'**
  String get endFailedTitle;

  /// No description provided for @endFailedBody.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t capture its screen.'**
  String endFailedBody(String device);

  /// No description provided for @endDecoderFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'This computer couldn\'t show the picture'**
  String get endDecoderFailedTitle;

  /// No description provided for @endDecoderFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The video from {device} didn\'t play here.'**
  String endDecoderFailedBody(String device);

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

  /// Video frames dropped, in the stats line
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} dropped}}'**
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
  /// **'{device} saw {here, select, tablet{this tablet\'s} other{this phone\'s}} screen for {duration} at {time}'**
  String auditShared(String device, String duration, String time, String here);

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
  /// **'{hours, plural, other{{hours} h}} {minutes, plural, other{{minutes} min}}'**
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

  /// No description provided for @sharingTitleSound.
  ///
  /// In en, this message translates to:
  /// **'Sharing screen and sound with {device}'**
  String sharingTitleSound(String device);

  /// No description provided for @sharingBodySound.
  ///
  /// In en, this message translates to:
  /// **'Everything on this screen is visible there, with sound. Since {time}.'**
  String sharingBodySound(String time);

  /// No description provided for @noticeSharingBodySound.
  ///
  /// In en, this message translates to:
  /// **'Everything on this screen is visible there, with sound'**
  String get noticeSharingBodySound;

  /// No description provided for @settingsSendSound.
  ///
  /// In en, this message translates to:
  /// **'Send sound too'**
  String get settingsSendSound;

  /// No description provided for @settingsSendSoundBody.
  ///
  /// In en, this message translates to:
  /// **'Computers that show this screen also hear what it plays: music, videos, games. Only while the screen is shared, and never the microphone. Some apps block this and stay silent.'**
  String get settingsSendSoundBody;

  /// No description provided for @settingsSendSoundPermission.
  ///
  /// In en, this message translates to:
  /// **'Android calls this permission \"record audio\" and files it under Microphone. Ferret only captures what the phone plays.'**
  String get settingsSendSoundPermission;

  /// No description provided for @settingsSendSoundDenied.
  ///
  /// In en, this message translates to:
  /// **'Android didn\'t allow it. To change that, open Ferret in Android\'s app settings, then Permissions → Microphone.'**
  String get settingsSendSoundDenied;

  /// No description provided for @settingsSendSoundUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Sending sound takes Android 10 or newer.'**
  String get settingsSendSoundUnsupported;

  /// No description provided for @settingsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{here, select, tablet{This tablet} other{This phone}} can\'t capture its screen'**
  String settingsUnsupported(String here);

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

  /// No description provided for @settingsPerDevice.
  ///
  /// In en, this message translates to:
  /// **'To stop one computer from asking, open it from Home.'**
  String get settingsPerDevice;

  /// No description provided for @summaryOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get summaryOff;

  /// No description provided for @summaryAsks.
  ///
  /// In en, this message translates to:
  /// **'Asks every time'**
  String get summaryAsks;

  /// No description provided for @summaryCantCapture.
  ///
  /// In en, this message translates to:
  /// **'Can\'t capture'**
  String get summaryCantCapture;

  /// No description provided for @permissionAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask to see {here, select, tablet{this tablet\'s} other{this phone\'s}} screen'**
  String permissionAsk(String here);

  /// No description provided for @permissionAskOff.
  ///
  /// In en, this message translates to:
  /// **'Screen is off for every computer. Turn it on in Settings → To your computer.'**
  String get permissionAskOff;

  /// No description provided for @healthAsks.
  ///
  /// In en, this message translates to:
  /// **'Asks on {device} every time'**
  String healthAsks(String device);

  /// No description provided for @healthTryAgainHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose Show screen to try again.'**
  String get healthTryAgainHelp;

  /// No description provided for @healthShareOff.
  ///
  /// In en, this message translates to:
  /// **'Off on {here, select, tablet{this tablet} other{this phone}}'**
  String healthShareOff(String here);

  /// No description provided for @healthShareOffHelp.
  ///
  /// In en, this message translates to:
  /// **'Open Settings → To your computer and turn on Let my computers ask to see this screen.'**
  String get healthShareOffHelp;

  /// No description provided for @healthShareBlocked.
  ///
  /// In en, this message translates to:
  /// **'Off for {device}'**
  String healthShareBlocked(String device);

  /// No description provided for @healthShareBlockedHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn on Ask to see {here, select, tablet{this tablet\'s} other{this phone\'s}} screen for {device}, further down this page.'**
  String healthShareBlockedHelp(String device, String here);

  /// No description provided for @healthSharing.
  ///
  /// In en, this message translates to:
  /// **'Sees {here, select, tablet{this tablet\'s} other{this phone\'s}} screen now'**
  String healthSharing(String here);

  /// No description provided for @healthShareAsks.
  ///
  /// In en, this message translates to:
  /// **'Asks you every time'**
  String get healthShareAsks;

  /// No description provided for @healthViewing.
  ///
  /// In en, this message translates to:
  /// **'Showing its screen here'**
  String get healthViewing;

  /// No description provided for @healthTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Off on {device}'**
  String healthTurnedOff(String device);

  /// No description provided for @healthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t share its screen'**
  String healthUnsupported(String device);

  /// No description provided for @healthCannotAsk.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t show the question'**
  String healthCannotAsk(String device);

  /// No description provided for @healthFailed.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t capture its screen'**
  String healthFailed(String device);

  /// No description provided for @healthDecoderFailed.
  ///
  /// In en, this message translates to:
  /// **'This computer couldn\'t show the picture'**
  String get healthDecoderFailed;

  /// No description provided for @targetCable.
  ///
  /// In en, this message translates to:
  /// **'Cable'**
  String get targetCable;

  /// No description provided for @targetWireless.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi debugging'**
  String get targetWireless;

  /// No description provided for @setupInstallToolBody.
  ///
  /// In en, this message translates to:
  /// **'Install Android\'s platform tools (they include adb) on {here, select, macOS{this Mac} windows{this PC} other{this computer}}. This page moves on by itself.'**
  String setupInstallToolBody(String here);

  /// No description provided for @setupDownloadToolTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Android\'s helper tool'**
  String get setupDownloadToolTitle;

  /// No description provided for @setupDownloadToolBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret downloads Android\'s platform tools from Google, about 16 MB, once.'**
  String get setupDownloadToolBody;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloading;

  /// No description provided for @setupDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The download didn\'t finish. Check {here, select, macOS{this Mac\'s} windows{this PC\'s} other{{here, select, macOS{this Mac} windows{this PC} other{this computer}}\'s}} internet connection and try again.'**
  String setupDownloadFailed(String here);

  /// No description provided for @setupStartToolTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Android\'s helper tool'**
  String get setupStartToolTitle;

  /// No description provided for @setupStartToolBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret isn\'t allowed to start adb on {here, select, macOS{this Mac} windows{this PC} other{this computer}}. Open Android Studio, or run adb start-server in Terminal. This page moves on by itself.'**
  String setupStartToolBody(String here);

  /// No description provided for @setupPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Ferret needs your OK on {here, select, macOS{this Mac} windows{this PC} other{this computer}}'**
  String setupPermissionTitle(String here);

  /// No description provided for @setupPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Ferret under Local Network in {here, select, macOS{this Mac\'s} windows{this PC\'s} other{{here, select, macOS{this Mac} windows{this PC} other{this computer}}\'s}} privacy settings.'**
  String setupPermissionBody(String here);

  /// Android navigation button, sent to the mirrored phone
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get buttonBack;

  /// Android navigation button, sent to the mirrored phone
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get buttonHome;

  /// Android navigation button, sent to the mirrored phone
  ///
  /// In en, this message translates to:
  /// **'Recents'**
  String get buttonRecents;

  /// No description provided for @receiverAirplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Show iPhone and iPad screens here'**
  String get receiverAirplayTitle;

  /// No description provided for @receiverAirplayBody.
  ///
  /// In en, this message translates to:
  /// **'This computer appears under Screen Mirroring in the iPhone\'s Control Center. You are asked before anything shows.'**
  String get receiverAirplayBody;

  /// No description provided for @receiverOtherTitle.
  ///
  /// In en, this message translates to:
  /// **'Let other devices send their screen here'**
  String get receiverOtherTitle;

  /// No description provided for @receiverOtherBody.
  ///
  /// In en, this message translates to:
  /// **'You are asked before anything shows.'**
  String get receiverOtherBody;

  /// No description provided for @allowTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} wants to show its screen here'**
  String allowTitle(String device);

  /// Button that accepts another device's request to see this screen
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get allow;

  /// No description provided for @dontAllow.
  ///
  /// In en, this message translates to:
  /// **'Don\'t allow'**
  String get dontAllow;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @showAgain.
  ///
  /// In en, this message translates to:
  /// **'Show again'**
  String get showAgain;

  /// No description provided for @askAgain.
  ///
  /// In en, this message translates to:
  /// **'Ask again'**
  String get askAgain;

  /// No description provided for @askAgainIn.
  ///
  /// In en, this message translates to:
  /// **'You can ask again in {time}.'**
  String askAgainIn(String time);

  /// Button that opens the steps to turn this on
  ///
  /// In en, this message translates to:
  /// **'How'**
  String get how;

  /// No description provided for @why.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get why;

  /// Button that wakes the phone's screen over the cable
  ///
  /// In en, this message translates to:
  /// **'Wake'**
  String get wake;

  /// Rejects an AirPlay connection from a device that isn't yours
  ///
  /// In en, this message translates to:
  /// **'Not mine'**
  String get notMine;

  /// No description provided for @showIt.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showIt;

  /// No description provided for @startingCableTitle.
  ///
  /// In en, this message translates to:
  /// **'Showing {device}…'**
  String startingCableTitle(String device);

  /// No description provided for @waitingNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing on {device}? Open the notice from Ferret.'**
  String waitingNothing(String device);

  /// No description provided for @waitingWhy.
  ///
  /// In en, this message translates to:
  /// **'Android asks every time. Ferret can\'t skip it, and wouldn\'t.'**
  String get waitingWhy;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timeLeft(String time);

  /// No description provided for @reconnectingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting to {device}…'**
  String reconnectingTitle(String device);

  /// No description provided for @lostTitle.
  ///
  /// In en, this message translates to:
  /// **'Lost {device}'**
  String lostTitle(String device);

  /// No description provided for @lostBody.
  ///
  /// In en, this message translates to:
  /// **'This picks up again when {device} is back.'**
  String lostBody(String device);

  /// No description provided for @lostCableBody.
  ///
  /// In en, this message translates to:
  /// **'Plug {device} back in. The picture picks up by itself.'**
  String lostCableBody(String device);

  /// No description provided for @notConnectedWaits.
  ///
  /// In en, this message translates to:
  /// **'This starts by itself when {device} connects.'**
  String notConnectedWaits(String device);

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @plugInTitle.
  ///
  /// In en, this message translates to:
  /// **'Plug {device} into {here, select, macOS{this Mac} windows{this PC} other{this computer}}'**
  String plugInTitle(String device, String here);

  /// No description provided for @plugInBody.
  ///
  /// In en, this message translates to:
  /// **'You can click and type on it too.'**
  String get plugInBody;

  /// No description provided for @buttonRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get buttonRotate;

  /// No description provided for @buttonKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get buttonKeyboard;

  /// No description provided for @buttonScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get buttonScreenshot;

  /// No description provided for @screenshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to {folder}'**
  String screenshotSaved(String folder);

  /// No description provided for @screenshotFailed.
  ///
  /// In en, this message translates to:
  /// **'The screenshot couldn\'t be saved.'**
  String get screenshotFailed;

  /// No description provided for @showInFinder.
  ///
  /// In en, this message translates to:
  /// **'Show in Finder'**
  String get showInFinder;

  /// No description provided for @showInFolder.
  ///
  /// In en, this message translates to:
  /// **'Show in folder'**
  String get showInFolder;

  /// No description provided for @buttonNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications panel'**
  String get buttonNotifications;

  /// No description provided for @buttonVolumeUp.
  ///
  /// In en, this message translates to:
  /// **'Volume up'**
  String get buttonVolumeUp;

  /// No description provided for @buttonVolumeDown.
  ///
  /// In en, this message translates to:
  /// **'Volume down'**
  String get buttonVolumeDown;

  /// Presses the phone's power button
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get buttonPower;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @tooltipWithKey.
  ///
  /// In en, this message translates to:
  /// **'{name} ({key})'**
  String tooltipWithKey(String name, String key);

  /// No description provided for @keyRightClick.
  ///
  /// In en, this message translates to:
  /// **'right-click'**
  String get keyRightClick;

  /// No description provided for @keyMiddleClick.
  ///
  /// In en, this message translates to:
  /// **'middle-click'**
  String get keyMiddleClick;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get viewOnly;

  /// No description provided for @viewOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'{device} shares its picture, not its controls. To click and type, plug it in.'**
  String viewOnlyBody(String device);

  /// No description provided for @viewOnlyAirplayBody.
  ///
  /// In en, this message translates to:
  /// **'An iPhone or iPad shares its picture, not its controls.'**
  String get viewOnlyAirplayBody;

  /// No description provided for @controlWithCable.
  ///
  /// In en, this message translates to:
  /// **'Control with the cable'**
  String get controlWithCable;

  /// No description provided for @viewOnlyToast.
  ///
  /// In en, this message translates to:
  /// **'View only.'**
  String get viewOnlyToast;

  /// No description provided for @keepToolbar.
  ///
  /// In en, this message translates to:
  /// **'Keep toolbar visible'**
  String get keepToolbar;

  /// Heading of the panel that picks where a shown phone's sound plays, and a row in the toolbar's More menu
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get soundTitle;

  /// Short state next to Sound in a menu: the phone's sound plays on this computer
  ///
  /// In en, this message translates to:
  /// **'Here'**
  String get soundDetailHere;

  /// Short state next to Sound in a menu: the sound stays on the phone
  ///
  /// In en, this message translates to:
  /// **'On the phone'**
  String get soundDetailThere;

  /// Short state next to Sound in a menu: no sound arrives
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get soundDetailNone;

  /// Choice: play the shown phone's sound on this computer
  ///
  /// In en, this message translates to:
  /// **'On {here, select, macOS{this Mac} windows{this PC} other{this computer}}'**
  String soundHere(String here);

  /// No description provided for @soundThere.
  ///
  /// In en, this message translates to:
  /// **'On {device}'**
  String soundThere(String device);

  /// No description provided for @soundVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get soundVolume;

  /// No description provided for @soundMovesNote.
  ///
  /// In en, this message translates to:
  /// **'{device} goes quiet while its sound plays here. Changing it restarts the picture.'**
  String soundMovesNote(String device);

  /// No description provided for @soundCopiesNote.
  ///
  /// In en, this message translates to:
  /// **'{device} keeps playing too: turn its volume down to hear it only here. Apps that block capture, like some video apps, stay silent.'**
  String soundCopiesNote(String device);

  /// No description provided for @soundNextTime.
  ///
  /// In en, this message translates to:
  /// **'{device} has to say yes again, so sound starts next time.'**
  String soundNextTime(String device);

  /// No description provided for @soundNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'{device} isn\'t sending its sound. On the phone, open Ferret, then Settings → Screen, and turn on Send sound too.'**
  String soundNotAllowed(String device);

  /// No description provided for @soundUnsupportedCable.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t send its sound. That takes Android 11 or newer, and an unlocked screen when the picture starts.'**
  String soundUnsupportedCable(String device);

  /// No description provided for @soundUnsupportedWifi.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t send its sound. That takes Android 10 or newer and the latest Ferret on it.'**
  String soundUnsupportedWifi(String device);

  /// No description provided for @soundFailed.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t capture its sound. Stop, then show the screen again.'**
  String soundFailed(String device);

  /// No description provided for @soundNoOutput.
  ///
  /// In en, this message translates to:
  /// **'This computer couldn\'t play the sound. Check its sound output.'**
  String get soundNoOutput;

  /// No description provided for @soundAirplay.
  ///
  /// In en, this message translates to:
  /// **'Sound over AirPlay isn\'t here yet. It stays on the iPhone.'**
  String get soundAirplay;

  /// No description provided for @soundWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sound…'**
  String get soundWaiting;

  /// No description provided for @qualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get qualityGood;

  /// Connection quality level, next to Good and Poor
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get qualitySlow;

  /// No description provided for @qualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get qualityPoor;

  /// Heading of the video quality panel (the picture of the stream, not a photo)
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get pictureTitle;

  /// Tooltip of the toolbar button that picks the picture quality
  ///
  /// In en, this message translates to:
  /// **'Picture: {quality}'**
  String pictureTooltip(String quality);

  /// No description provided for @presetAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get presetAuto;

  /// No description provided for @presetAutoBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret adapts'**
  String get presetAutoBody;

  /// No description provided for @presetSharp.
  ///
  /// In en, this message translates to:
  /// **'Sharp'**
  String get presetSharp;

  /// No description provided for @presetSharpBody.
  ///
  /// In en, this message translates to:
  /// **'Full size'**
  String get presetSharpBody;

  /// No description provided for @presetFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get presetFast;

  /// No description provided for @presetFastBody.
  ///
  /// In en, this message translates to:
  /// **'Smaller, smooth'**
  String get presetFastBody;

  /// No description provided for @presetRestarts.
  ///
  /// In en, this message translates to:
  /// **'Changing it restarts the picture.'**
  String get presetRestarts;

  /// No description provided for @presetNextTime.
  ///
  /// In en, this message translates to:
  /// **'{device} has to say yes again for a change, so it applies next time.'**
  String presetNextTime(String device);

  /// No description provided for @presetAirplay.
  ///
  /// In en, this message translates to:
  /// **'The iPhone picks the quality.'**
  String get presetAirplay;

  /// No description provided for @basicPicture.
  ///
  /// In en, this message translates to:
  /// **'Basic picture on {here, select, macOS{this Mac} windows{this PC} other{this computer}} for now (about 10 a second).'**
  String basicPicture(String here);

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @wayWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get wayWifi;

  /// No description provided for @wayCable.
  ///
  /// In en, this message translates to:
  /// **'Cable'**
  String get wayCable;

  /// No description provided for @wayAirplay.
  ///
  /// In en, this message translates to:
  /// **'AirPlay'**
  String get wayAirplay;

  /// No description provided for @noticeViaCable.
  ///
  /// In en, this message translates to:
  /// **'Showing over the cable instead.'**
  String get noticeViaCable;

  /// No description provided for @noticeCableNoAsk.
  ///
  /// In en, this message translates to:
  /// **'Over a cable, {device} doesn\'t ask each time. Only do this with your own phone.'**
  String noticeCableNoAsk(String device);

  /// No description provided for @noticeSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow connection to {device}.'**
  String noticeSlow(String device);

  /// No description provided for @noticeSlowHelp.
  ///
  /// In en, this message translates to:
  /// **'Slow connection to {device}. Move closer to the Wi-Fi, or plug it in.'**
  String noticeSlowHelp(String device);

  /// No description provided for @useFast.
  ///
  /// In en, this message translates to:
  /// **'Use Fast'**
  String get useFast;

  /// No description provided for @textFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Type or paste, then press Enter'**
  String get textFieldHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @replaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop showing {current} and show {next}?'**
  String replaceTitle(String current, String next);

  /// No description provided for @replaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Show {device}'**
  String replaceConfirm(String device);

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop showing {device}?'**
  String leaveTitle(String device);

  /// No description provided for @leaveBody.
  ///
  /// In en, this message translates to:
  /// **'Leaving this page stops sharing on both devices.'**
  String get leaveBody;

  /// No description provided for @keepShowing.
  ///
  /// In en, this message translates to:
  /// **'Keep showing'**
  String get keepShowing;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Show {device} with a cable'**
  String setupTitle(String device);

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No app needed on the phone.'**
  String get setupSubtitle;

  /// No description provided for @stepPlug.
  ///
  /// In en, this message translates to:
  /// **'Plug the phone into {here, select, macOS{this Mac} windows{this PC} other{this computer}}'**
  String stepPlug(String here);

  /// No description provided for @stepDebugging.
  ///
  /// In en, this message translates to:
  /// **'Turn on USB debugging'**
  String get stepDebugging;

  /// No description provided for @stepDebuggingOn.
  ///
  /// In en, this message translates to:
  /// **'On the phone:'**
  String get stepDebuggingOn;

  /// No description provided for @stepDebugging1.
  ///
  /// In en, this message translates to:
  /// **'Settings → About phone'**
  String get stepDebugging1;

  /// No description provided for @stepDebugging2.
  ///
  /// In en, this message translates to:
  /// **'Tap Build number 7 times'**
  String get stepDebugging2;

  /// No description provided for @stepDebugging3.
  ///
  /// In en, this message translates to:
  /// **'Settings → System → Developer options → USB debugging'**
  String get stepDebugging3;

  /// No description provided for @brandsToggle.
  ///
  /// In en, this message translates to:
  /// **'Samsung, Xiaomi, others'**
  String get brandsToggle;

  /// No description provided for @brandsBody.
  ///
  /// In en, this message translates to:
  /// **'Samsung: Build number is under About phone → Software information.\nXiaomi: tap the OS version instead of Build number, and also turn on USB debugging (Security settings), or clicks won\'t work.\nAny other phone: search its Settings for Build number.'**
  String get brandsBody;

  /// No description provided for @stepAllow.
  ///
  /// In en, this message translates to:
  /// **'Tap Allow on the phone'**
  String get stepAllow;

  /// No description provided for @stepAllowNamed.
  ///
  /// In en, this message translates to:
  /// **'On {device}: tap Allow. Tick Always allow from this computer.'**
  String stepAllowNamed(String device);

  /// No description provided for @setupWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the phone…'**
  String get setupWaiting;

  /// No description provided for @setupCables.
  ///
  /// In en, this message translates to:
  /// **'Many cables only charge. Try another one.'**
  String get setupCables;

  /// No description provided for @setupPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Once allowed, {here, select, macOS{this Mac} windows{this PC} other{this computer}} can see and control the phone without asking. Only do this with your own phone.'**
  String setupPrivacy(String here);

  /// No description provided for @setupUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This computer can\'t show a phone over a cable.'**
  String get setupUnsupported;

  /// No description provided for @airplayOn.
  ///
  /// In en, this message translates to:
  /// **'On {device}:'**
  String airplayOn(String device);

  /// No description provided for @airplayStep1.
  ///
  /// In en, this message translates to:
  /// **'Open Control Center (swipe down from the top right)'**
  String get airplayStep1;

  /// No description provided for @airplayStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap Screen Mirroring'**
  String get airplayStep2;

  /// No description provided for @airplayStep3.
  ///
  /// In en, this message translates to:
  /// **'Pick “{computer}”'**
  String airplayStep3(String computer);

  /// While this computer waits for an AirPlay connection; the time left, "4:59"
  ///
  /// In en, this message translates to:
  /// **'Listening… {time}'**
  String airplayListeningLeft(String time);

  /// One numbered step of a setup guide
  ///
  /// In en, this message translates to:
  /// **'{number}. {step}'**
  String setupStepNumbered(int number, String step);

  /// No description provided for @airplayNote.
  ///
  /// In en, this message translates to:
  /// **'View only. No sound. Beta: an iOS update can break it.'**
  String get airplayNote;

  /// No description provided for @airplayMacTitle.
  ///
  /// In en, this message translates to:
  /// **'Macs already do this'**
  String get airplayMacTitle;

  /// No description provided for @airplayMacBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}, pick this Mac under Screen Mirroring, or use iPhone Mirroring.'**
  String airplayMacBody(String device);

  /// No description provided for @useFerretAnyway.
  ///
  /// In en, this message translates to:
  /// **'Use Ferret anyway'**
  String get useFerretAnyway;

  /// No description provided for @airplayConnecting.
  ///
  /// In en, this message translates to:
  /// **'{device} is connecting'**
  String airplayConnecting(String device);

  /// No description provided for @airplayConnectingBody.
  ///
  /// In en, this message translates to:
  /// **'The name is what the device calls itself. Say yes only if it is yours.'**
  String get airplayConnectingBody;

  /// No description provided for @airplayTimedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody picked {here, select, macOS{this Mac} windows{this PC} other{this computer}}'**
  String airplayTimedOutTitle(String here);

  /// No description provided for @airplayTimedOutBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret listened for two minutes, then stopped.'**
  String get airplayTimedOutBody;

  /// No description provided for @listenAgain.
  ///
  /// In en, this message translates to:
  /// **'Listen again'**
  String get listenAgain;

  /// No description provided for @viewingDetail.
  ///
  /// In en, this message translates to:
  /// **'Since {time} · {way}'**
  String viewingDetail(String time, String way);

  /// No description provided for @viewingAsking.
  ///
  /// In en, this message translates to:
  /// **'Asking {device}…'**
  String viewingAsking(String device);

  /// No description provided for @lookForCableTitle.
  ///
  /// In en, this message translates to:
  /// **'Look for phones on a cable'**
  String get lookForCableTitle;

  /// No description provided for @lookForCableBody.
  ///
  /// In en, this message translates to:
  /// **'Shows any Android phone plugged in with USB debugging on.'**
  String get lookForCableBody;

  /// No description provided for @summaryCable.
  ///
  /// In en, this message translates to:
  /// **'Looks for a cable'**
  String get summaryCable;

  /// No description provided for @sharingReconnecting.
  ///
  /// In en, this message translates to:
  /// **'{device} dropped off. Waiting a moment for it to come back.'**
  String sharingReconnecting(String device);

  /// No description provided for @endStoppedHereTitle.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get endStoppedHereTitle;

  /// No description provided for @endStoppedHereBody.
  ///
  /// In en, this message translates to:
  /// **'{device} no longer shares its screen.'**
  String endStoppedHereBody(String device);

  /// No description provided for @allowNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Say yes only if it is yours.'**
  String get allowNoticeBody;

  /// Toolbar chip on a phone shown over Wi-Fi: asks the phone's owner to let this computer click and type there
  ///
  /// In en, this message translates to:
  /// **'Control'**
  String get controlAsk;

  /// The Control chip while the phone's owner is being asked
  ///
  /// In en, this message translates to:
  /// **'Asking…'**
  String get controlAsking;

  /// No description provided for @noticeControlAsking.
  ///
  /// In en, this message translates to:
  /// **'On {device}, tap Once or Always to let {here, select, macOS{this Mac} windows{this PC} other{this computer}} click and type there.'**
  String noticeControlAsking(String device, String here);

  /// No description provided for @noticeControlAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can click and type on {device} now.'**
  String noticeControlAllowed(String device);

  /// No description provided for @noticeControlDenied.
  ///
  /// In en, this message translates to:
  /// **'{device} said no to control. You can still watch.'**
  String noticeControlDenied(String device);

  /// No description provided for @noticeControlTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Nobody answered on {device}. Click Control to ask again.'**
  String noticeControlTimedOut(String device);

  /// No description provided for @noticeControlStopped.
  ///
  /// In en, this message translates to:
  /// **'{device} stopped control. You can still watch.'**
  String noticeControlStopped(String device);

  /// No description provided for @viewOnlySetupBody.
  ///
  /// In en, this message translates to:
  /// **'To click and type over Wi-Fi, turn on Ferret control on {device}: open Ferret there, then Settings → To your computer.'**
  String viewOnlySetupBody(String device);

  /// No description provided for @controlAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Let {computer} control {phone} while showing its screen?'**
  String controlAskTitle(String computer, String phone);

  /// No description provided for @controlAskCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Let {computer} control {phone}?'**
  String controlAskCardTitle(String computer, String phone);

  /// No description provided for @controlAskBody.
  ///
  /// In en, this message translates to:
  /// **'While it shows this screen, {computer} can tap, swipe and type here, until you stop it.'**
  String controlAskBody(String computer);

  /// Answer: let this computer control the phone now and every time after
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get controlAlways;

  /// Answer: let this computer control the phone this time
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get controlOnce;

  /// Answer: don't let this computer control the phone
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get controlNo;

  /// No description provided for @controlledTitle.
  ///
  /// In en, this message translates to:
  /// **'Being controlled by {computer}'**
  String controlledTitle(String computer);

  /// No description provided for @controlledBody.
  ///
  /// In en, this message translates to:
  /// **'It can tap and type here while it shows this screen.'**
  String get controlledBody;

  /// No description provided for @controlStop.
  ///
  /// In en, this message translates to:
  /// **'Stop control'**
  String get controlStop;

  /// While a computer controls the phone: ends both control and showing the screen.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get controlStopSharing;

  /// Android notification channel name
  ///
  /// In en, this message translates to:
  /// **'Control from a computer'**
  String get noticeControlChannel;

  /// No description provided for @settingsControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Control from a computer'**
  String get settingsControlTitle;

  /// No description provided for @settingsControlPowerUps.
  ///
  /// In en, this message translates to:
  /// **'A computer that shows this screen can tap and type here, through Power-ups. It asks you first.'**
  String get settingsControlPowerUps;

  /// No description provided for @settingsControlService.
  ///
  /// In en, this message translates to:
  /// **'Ferret control is on. A computer that shows this screen can tap and type here after it asks you.'**
  String get settingsControlService;

  /// No description provided for @settingsControlOff.
  ///
  /// In en, this message translates to:
  /// **'To let a computer that shows this screen tap and type here, turn on Ferret control in Android\'s Accessibility settings.'**
  String get settingsControlOff;

  /// No description provided for @settingsControlTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on Ferret control…'**
  String get settingsControlTurnOn;

  /// Short button for settingsControlTurnOn; the full sentence is its tooltip
  ///
  /// In en, this message translates to:
  /// **'Turn on control…'**
  String get settingsControlTurnOnShort;

  /// No description provided for @settingsControlOpen.
  ///
  /// In en, this message translates to:
  /// **'Accessibility settings'**
  String get settingsControlOpen;

  /// Short button for settingsControlOpen; the full name is its tooltip
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get settingsControlOpenShort;

  /// No description provided for @settingsControlAlwaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 computer controls} other{{count} computers control}} {here, select, tablet{this tablet} other{this phone}} without asking.'**
  String settingsControlAlwaysCount(int count, String here);

  /// No description provided for @settingsControlAskAgain.
  ///
  /// In en, this message translates to:
  /// **'Ask every time'**
  String get settingsControlAskAgain;

  /// No description provided for @controlDisclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on Ferret control?'**
  String get controlDisclosureTitle;

  /// No description provided for @controlDisclosureBody.
  ///
  /// In en, this message translates to:
  /// **'Ferret control is an Android accessibility service. With it, a computer you paired can tap, swipe, press Back and Home, and type on {here, select, tablet{this tablet} other{this phone}}.\n\nIt acts only while you show this screen to that computer and said yes to control. A notice says so the whole time, with Stop.\n\nTo type, it reads the text field you type into. It reads nothing else, keeps nothing, and sends nothing anywhere.'**
  String controlDisclosureBody(String here);

  /// No description provided for @controlDisclosureSteps.
  ///
  /// In en, this message translates to:
  /// **'Next, in Accessibility, tap Ferret control and turn it on.'**
  String get controlDisclosureSteps;

  /// No description provided for @controlDisclosureOpen.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get controlDisclosureOpen;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use {device}\'s camera'**
  String useCamera(String device);

  /// Short button for useCamera; the full sentence with the device name is its tooltip
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get useCameraShort;

  /// No description provided for @cameraWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} — Camera'**
  String cameraWindowTitle(String device);

  /// Toolbar button over a phone's camera that saves what it shows as a PNG, like a screenshot
  ///
  /// In en, this message translates to:
  /// **'Save a picture'**
  String get cameraSavePicture;

  /// No description provided for @cameraSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get cameraSwitch;

  /// No description provided for @cameraUseAgain.
  ///
  /// In en, this message translates to:
  /// **'Use again'**
  String get cameraUseAgain;

  /// No description provided for @cameraPictureNote.
  ///
  /// In en, this message translates to:
  /// **'720p at 30 frames a second, like a webcam.'**
  String get cameraPictureNote;

  /// No description provided for @cameraWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}, tap Once or Always to turn its camera on.'**
  String cameraWaitingBody(String device);

  /// No description provided for @cameraWaitingNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing on {device}? Open Ferret there.'**
  String cameraWaitingNothing(String device);

  /// No description provided for @cameraDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Someone tapped No on {device}.'**
  String cameraDeniedBody(String device);

  /// No description provided for @cameraBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} is busy'**
  String cameraBusyTitle(String device);

  /// No description provided for @cameraBusyBody.
  ///
  /// In en, this message translates to:
  /// **'Its screen or its camera is already on for a device. Stop that one first.'**
  String get cameraBusyBody;

  /// No description provided for @cameraUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t share its camera'**
  String cameraUnsupportedTitle(String device);

  /// No description provided for @cameraUnsupportedBody.
  ///
  /// In en, this message translates to:
  /// **'Using a phone\'s camera needs an Android phone with the latest Ferret.'**
  String get cameraUnsupportedBody;

  /// No description provided for @cameraTurnedOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera is off on {device}'**
  String cameraTurnedOffTitle(String device);

  /// No description provided for @cameraTurnedOffBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret → Settings → To your computer and turn on Let my computers ask to use this camera. Then open {here, select, macOS{this Mac} windows{this PC} other{this computer}} there and check that it may ask.'**
  String cameraTurnedOffBody(String device, String here);

  /// No description provided for @cameraCannotStartTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t turn its camera on'**
  String cameraCannotStartTitle(String device);

  /// No description provided for @cameraCannotStartBody.
  ///
  /// In en, this message translates to:
  /// **'On {device}: open Ferret and allow the camera. Then ask again.'**
  String cameraCannotStartBody(String device);

  /// No description provided for @cameraStoppedHereBody.
  ///
  /// In en, this message translates to:
  /// **'{device}\'s camera is off.'**
  String cameraStoppedHereBody(String device);

  /// No description provided for @cameraSystemEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} turned its camera off'**
  String cameraSystemEndedTitle(String device);

  /// No description provided for @cameraSystemEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Android closed the camera, or another app took it. Use it again when {device} is ready.'**
  String cameraSystemEndedBody(String device);

  /// No description provided for @cameraFailedBody.
  ///
  /// In en, this message translates to:
  /// **'{device} couldn\'t start its camera.'**
  String cameraFailedBody(String device);

  /// No description provided for @cameraViewingTitle.
  ///
  /// In en, this message translates to:
  /// **'Using {device}\'s camera'**
  String cameraViewingTitle(String device);

  /// No description provided for @cameraAuditViewed.
  ///
  /// In en, this message translates to:
  /// **'You used {device}\'s camera for {duration} at {time}'**
  String cameraAuditViewed(String device, String duration, String time);

  /// No description provided for @cameraAuditShared.
  ///
  /// In en, this message translates to:
  /// **'{device} used {here, select, tablet{this tablet\'s} other{this phone\'s}} camera for {duration} at {time}'**
  String cameraAuditShared(
    String device,
    String duration,
    String time,
    String here,
  );

  /// No description provided for @cameraLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop using {device}\'s camera?'**
  String cameraLeaveTitle(String device);

  /// No description provided for @cameraLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Leaving this page turns the camera off.'**
  String get cameraLeaveBody;

  /// No description provided for @cameraKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it on'**
  String get cameraKeep;

  /// No description provided for @cameraAskTitle.
  ///
  /// In en, this message translates to:
  /// **'{computer} wants to use your camera'**
  String cameraAskTitle(String computer);

  /// No description provided for @cameraAskBody.
  ///
  /// In en, this message translates to:
  /// **'It will see through the camera and hear the microphone, until you stop it.'**
  String get cameraAskBody;

  /// No description provided for @cameraOnTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera on for {computer}'**
  String cameraOnTitle(String computer);

  /// No description provided for @cameraOnBody.
  ///
  /// In en, this message translates to:
  /// **'It sees and hears through {here, select, tablet{this tablet} other{this phone}}. Since {time}.'**
  String cameraOnBody(String time, String here);

  /// No description provided for @cameraOnBodySilent.
  ///
  /// In en, this message translates to:
  /// **'It sees through {here, select, tablet{this tablet\'s} other{this phone\'s}} camera. The microphone is off. Since {time}.'**
  String cameraOnBodySilent(String time, String here);

  /// No description provided for @noticeCameraBody.
  ///
  /// In en, this message translates to:
  /// **'It sees and hears through {here, select, tablet{this tablet} other{this phone}}'**
  String noticeCameraBody(String here);

  /// No description provided for @noticeCameraBodySilent.
  ///
  /// In en, this message translates to:
  /// **'It sees through {here, select, tablet{this tablet\'s} other{this phone\'s}} camera'**
  String noticeCameraBodySilent(String here);

  /// No description provided for @noticeCameraChannel.
  ///
  /// In en, this message translates to:
  /// **'Camera for a computer'**
  String get noticeCameraChannel;

  /// No description provided for @settingsCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera for a computer'**
  String get settingsCameraTitle;

  /// No description provided for @settingsCameraAllow.
  ///
  /// In en, this message translates to:
  /// **'Let my computers ask to use this camera'**
  String get settingsCameraAllow;

  /// No description provided for @settingsCameraAllowBody.
  ///
  /// In en, this message translates to:
  /// **'You answer Once, Always or No. A notice with Stop stays up while the camera is on.'**
  String get settingsCameraAllowBody;

  /// No description provided for @settingsCameraAlwaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 computer uses this camera without asking.} other{{count} computers use this camera without asking.}}'**
  String settingsCameraAlwaysCount(int count);

  /// No description provided for @permissionCameraAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask to use {here, select, tablet{this tablet\'s} other{this phone\'s}} camera'**
  String permissionCameraAsk(String here);

  /// No description provided for @permissionCameraAskOff.
  ///
  /// In en, this message translates to:
  /// **'Camera is off for every computer. Turn it on in Settings → To your computer.'**
  String get permissionCameraAskOff;

  /// No description provided for @cameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraTitle;

  /// Device action on a paired computer: extends this computer's desktop onto it
  ///
  /// In en, this message translates to:
  /// **'Use {device} as a display'**
  String displayUse(String device);

  /// No description provided for @displayStopUsing.
  ///
  /// In en, this message translates to:
  /// **'Stop using {device} as a display'**
  String displayStopUsing(String device);

  /// Short button for displayUse; the full sentence with the device name is its tooltip
  ///
  /// In en, this message translates to:
  /// **'Use as display'**
  String get displayUseShort;

  /// Short button for displayStopUsing; the full sentence with the device name is its tooltip
  ///
  /// In en, this message translates to:
  /// **'Stop display'**
  String get displayStopShort;

  /// No description provided for @displayAskingTitle.
  ///
  /// In en, this message translates to:
  /// **'Asking {device} to be a display…'**
  String displayAskingTitle(String device);

  /// No description provided for @displayAskingBody.
  ///
  /// In en, this message translates to:
  /// **'Someone on {device} has to say yes there.'**
  String displayAskingBody(String device);

  /// No description provided for @displayStartingTitle.
  ///
  /// In en, this message translates to:
  /// **'Making a display for {device}…'**
  String displayStartingTitle(String device);

  /// Pinned Activity line on the computer whose desktop is extended
  ///
  /// In en, this message translates to:
  /// **'{device} is a display for {here, select, macOS{this Mac} windows{this PC} other{this computer}}'**
  String displayExtendingTitle(String device, String here);

  /// No description provided for @displayExtendingDetail.
  ///
  /// In en, this message translates to:
  /// **'Since {time} · Arrange it in System Settings → Displays'**
  String displayExtendingDetail(String time);

  /// Activity line after using another computer as a display, by how it ended
  ///
  /// In en, this message translates to:
  /// **'{end, select, declined{{device} said no to being a display} timedOut{Nobody answered on {device}} busy{{device} is already another computer\'s display} unsupported{{device} can\'t be a display yet. Update Ferret there.} notConnected{{device} isn\'t connected} noAnswer{{device} didn\'t answer} cannotExtend{This Mac can\'t make an extra display. It needs macOS 12.3 or later.} needsScreenRecording{Allow Ferret in Screen Recording to use {device} as a display} stoppedHere{Stopped using {device} as a display} stoppedThere{{device} stopped being a display} lostConnection{Lost {device}, so its display went away} systemEnded{macOS ended the display on {device}} other{The display on {device} stopped working}}'**
  String displayEnded(String device, String end);

  /// No description provided for @displayScreenRecordingBody.
  ///
  /// In en, this message translates to:
  /// **'System Settings → Privacy & Security → Screen Recording. Turn on Ferret, then quit and open it again.'**
  String get displayScreenRecordingBody;

  /// No description provided for @displayOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get displayOpenSettings;

  /// Question on the computer that would become another computer's extra display
  ///
  /// In en, this message translates to:
  /// **'{device} wants to use {here, select, macOS{this Mac} windows{this PC} android{this phone} tablet{this tablet} other{this computer}} as a display'**
  String displayAllowTitle(String device, String here);

  /// No description provided for @displayAllowBody.
  ///
  /// In en, this message translates to:
  /// **'Your mouse and keyboard will work on its desktop. Allow only if it\'s yours.'**
  String get displayAllowBody;

  /// Button that lets another computer use this one as its display
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get displayAllow;

  /// Pinned Activity line on the computer showing another computer's extra display
  ///
  /// In en, this message translates to:
  /// **'{here, select, macOS{This Mac} windows{This PC} android{This phone} tablet{This tablet} other{This computer}} is {device}\'s display'**
  String displayShowingTitle(String device, String here);

  /// No description provided for @displayShowingDetail.
  ///
  /// In en, this message translates to:
  /// **'Since {time} · Esc leaves full screen'**
  String displayShowingDetail(String time);

  /// No description provided for @displayWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'{device} — Display'**
  String displayWindowTitle(String device);

  /// No description provided for @displayConnectingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {device}…'**
  String displayConnectingTitle(String device);

  /// No description provided for @displayConnectingBody.
  ///
  /// In en, this message translates to:
  /// **'{device} is making a display the size of this screen.'**
  String displayConnectingBody(String device);

  /// No description provided for @displayBarTitle.
  ///
  /// In en, this message translates to:
  /// **'{device}\'s display'**
  String displayBarTitle(String device);

  /// No description provided for @displayEscHint.
  ///
  /// In en, this message translates to:
  /// **'Esc leaves full screen'**
  String get displayEscHint;

  /// What the display window says when it ended, by how
  ///
  /// In en, this message translates to:
  /// **'{end, select, stoppedOnPhone{{device} stopped using {here, select, macOS{this Mac} windows{this PC} android{this phone} tablet{this tablet} other{this computer}} as a display} stoppedHere{Stopped being {device}\'s display} lostConnection{Lost {device}} noAnswer{{device} didn\'t send its display} denied{{device} took its offer back} other{{device}\'s display stopped working}}'**
  String displayViewEnded(String device, String end, String here);

  /// No description provided for @displayNoInput.
  ///
  /// In en, this message translates to:
  /// **'{device} can\'t take your clicks yet: allow Ferret in Accessibility there.'**
  String displayNoInput(String device);

  /// Under the question on a phone or tablet that would become a computer's extra display
  ///
  /// In en, this message translates to:
  /// **'Your fingers will work as its mouse. Allow only if it\'s yours.'**
  String get displayAllowBodyTouch;

  /// No description provided for @displayShowingSince.
  ///
  /// In en, this message translates to:
  /// **'Since {time}'**
  String displayShowingSince(String time);

  /// On the bar over a computer's display on a phone or tablet: how fingers work there
  ///
  /// In en, this message translates to:
  /// **'Tap to click · Hold to right-click · Two fingers scroll'**
  String get displayTouchHint;

  /// Screen reader label of the small handle at the top of a computer's display on a phone
  ///
  /// In en, this message translates to:
  /// **'Show the bar for {device}\'s display'**
  String displayHandleLabel(String device);

  /// No description provided for @displayStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop being {device}\'s display?'**
  String displayStopTitle(String device);

  /// No description provided for @displayStopBody.
  ///
  /// In en, this message translates to:
  /// **'Its windows on this screen go back to {device}.'**
  String displayStopBody(String device);

  /// A small tag beside a feature that works in tests but hasn't been tried on enough real devices yet
  ///
  /// In en, this message translates to:
  /// **'Beta'**
  String get beta;

  /// Shown when resting on the Beta tag
  ///
  /// In en, this message translates to:
  /// **'Works in our tests, not yet on enough real devices'**
  String get betaTooltip;

  /// A tooltip or menu item for a feature in beta, such as 'Use MacBook Air as a display (beta)'
  ///
  /// In en, this message translates to:
  /// **'{text} (beta)'**
  String inBeta(String text);
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_MirroringLocalizationsDelegate old) => false;
}

MirroringLocalizations lookupMirroringLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return MirroringLocalizationsEn();
    case 'vi':
      return MirroringLocalizationsVi();
  }

  throw FlutterError(
    'MirroringLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
