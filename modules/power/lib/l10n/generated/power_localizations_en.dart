// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'power_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PowerLocalizationsEn extends PowerLocalizations {
  PowerLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Power-ups';

  @override
  String get back => 'Back';

  @override
  String get settingsUnsupported =>
      'Power-ups are extra abilities for Android phones. There\'s nothing to set up here.';

  @override
  String get settingsSummaryStandard =>
      'Ferret runs as a normal app. With Shizuku or root it can also send your clipboard in the background.';

  @override
  String get settingsSummaryShizuku =>
      'Shizuku is on. Ferret can send your clipboard in the background.';

  @override
  String get settingsSummaryRoot =>
      'Root is on. Ferret can send your clipboard in the background, also after a restart.';

  @override
  String get settingsOpen => 'Open Power-ups';

  @override
  String get ladderTitle => 'What this phone lets Ferret do';

  @override
  String get rungBasic => 'Basic';

  @override
  String get rungNotifications => '+ Notifications';

  @override
  String get rungMessagesAndCalls => '+ Messages & calls';

  @override
  String get rungShizuku => '+ Shizuku';

  @override
  String get rungRoot => '+ Root';

  @override
  String get rungOn => 'On';

  @override
  String get rungOff => 'Not on yet';

  @override
  String get perkFiles => 'Send and receive files';

  @override
  String get perkClipboardTap => 'Send your clipboard with a tap';

  @override
  String get perkHandoff => 'Continue a page on another device';

  @override
  String get perkMedia => 'Control what\'s playing';

  @override
  String get perkFind => 'Ring a lost device';

  @override
  String get perkNotifications =>
      'See this phone\'s notifications on your other devices';

  @override
  String get perkReplies => 'Reply to them and dismiss them from there';

  @override
  String get perkMessages => 'Read and answer text messages from your computer';

  @override
  String get perkCalls => 'See who\'s calling, then answer or decline';

  @override
  String get perkClipboardBackground =>
      'Send what you copy on its own, also in the background';

  @override
  String get perkOneTapSetup =>
      'Turn on notification access and background running with one tap';

  @override
  String get perkSameAsShizuku => 'Everything Shizuku adds';

  @override
  String get perkSurvivesRestart => 'Keeps working after the phone restarts';

  @override
  String get notificationsOpenSettings => 'Open notification access';

  @override
  String get notificationsTurnOnNow => 'Turn on now';

  @override
  String get notificationsRestricted =>
      'If Android says the setting is restricted, open App info, tap the three dots and choose Allow restricted settings. Then try again.';

  @override
  String get appInfo => 'App info';

  @override
  String get messagesHint =>
      'Ferret asks for these when you turn on Messages or Calls. Said no by mistake? Change it in App info.';

  @override
  String get shizukuTitle => 'Set up Shizuku';

  @override
  String get shizukuIntro =>
      'Shizuku is a free, open-source app. It lets Ferret do a few things Android keeps for the system, without rooting your phone.';

  @override
  String get stepInstallTitle => '1. Install Shizuku';

  @override
  String get stepInstallBody =>
      'Get it from its website. It\'s on F-Droid too.';

  @override
  String get stepInstallButton => 'Get Shizuku';

  @override
  String get stepStartTitle => '2. Start Shizuku';

  @override
  String get stepStartBody =>
      'Open Shizuku and follow its Start steps, then come back here. Ferret checks again when you return.';

  @override
  String get stepStartButton => 'Open Shizuku';

  @override
  String get stepAllowTitle => '3. Allow Ferret';

  @override
  String get stepAllowBody =>
      'Shizuku asks whether Ferret may use it. Choose Allow all the time.';

  @override
  String get stepAllowButton => 'Allow Ferret';

  @override
  String get shizukuOn => 'Shizuku is on.';

  @override
  String get shizukuOnBody =>
      'Next: turn on Send in the background in the Clipboard settings. Shizuku stops when the phone restarts; start it again from its app.';

  @override
  String get stopUsingShizuku => 'Stop using Shizuku';

  @override
  String get noticeShizukuRefused =>
      'Shizuku said no. Open Shizuku, allow Ferret in its list of apps, then try again.';

  @override
  String get noticeShizukuNotOpened =>
      'Couldn\'t open Shizuku. Check that it\'s installed.';

  @override
  String get noticeLinkFailed =>
      'Couldn\'t open the browser. Search for Shizuku on F-Droid or GitHub.';

  @override
  String get noticeGrantFailed =>
      'Android didn\'t take the change. Try again, or turn it on in this phone\'s Settings.';

  @override
  String get noticeRootRefused =>
      'Root access was denied. Allow Ferret in your root manager, then try again.';

  @override
  String get noticeSettingsNotOpened =>
      'Couldn\'t open this phone\'s Settings. Open Settings, then Apps, then Ferret.';

  @override
  String get batteryTitle => 'Keep Ferret running in the background';

  @override
  String get batteryBody =>
      'Stops Android from putting Ferret to sleep, so your devices stay connected.';

  @override
  String get batteryOn => 'Ferret may run in the background.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get rootTitle => 'Root';

  @override
  String get rootNotFound =>
      'This phone isn\'t rooted, and it doesn\'t need to be: Shizuku adds the same features.';

  @override
  String get rootFound => 'Root found on this phone.';

  @override
  String rootFoundWith(String manager) {
    return 'Root found on this phone ($manager).';
  }

  @override
  String get rootWarning =>
      'Root gives an app full control of your phone. Turn this on only if you rooted the phone yourself. Ferret uses root for what\'s listed above and nothing else, and only while this is on.';

  @override
  String get useRoot => 'Use root';

  @override
  String get rootPromptHint => 'Your root manager will ask you to confirm.';

  @override
  String get rootOn => 'Root is on.';

  @override
  String get stopUsingRoot => 'Stop using root';

  @override
  String get cardStartShizuku =>
      'Start Shizuku and Ferret sends what you copy on its own.';

  @override
  String get cardAllowShizuku =>
      'Allow Shizuku and Ferret sends what you copy on its own.';

  @override
  String get cardShizukuStopped =>
      'Shizuku stopped, so background clipboard is paused. It stops whenever the phone restarts. Start it again.';

  @override
  String get cardShizukuRevoked =>
      'Shizuku no longer allows Ferret, so background clipboard is paused.';

  @override
  String get cardUseRoot =>
      'Use root and Ferret sends what you copy on its own.';

  @override
  String get cardRootLost =>
      'Root access was taken away, so background clipboard is paused.';

  @override
  String get cardSetUp => 'Open Power-ups';

  @override
  String get cardAskAgain => 'Ask again';
}
