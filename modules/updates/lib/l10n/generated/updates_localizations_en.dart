// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'updates_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class UpdatesLocalizationsEn extends UpdatesLocalizations {
  UpdatesLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Updates';

  @override
  String get checkSwitch => 'Check for updates';

  @override
  String get checkSwitchBody =>
      'Once a day, Ferret asks GitHub for its newest version. It sends nothing about you or your devices.';

  @override
  String get betaSwitch => 'Include beta versions';

  @override
  String get betaSwitchBody =>
      'Try what\'s next before everyone else. Betas may have rough edges.';

  @override
  String get checkNow => 'Check now';

  @override
  String get checkNowTooltip => 'Ask GitHub for Ferret\'s newest version now';

  @override
  String get checking => 'Checking…';

  @override
  String upToDate(String version) {
    return 'Ferret $version is the newest version.';
  }

  @override
  String get checkFailed => 'Couldn\'t reach GitHub. Try again later.';

  @override
  String statusOff(String version) {
    return 'Ferret doesn\'t check for updates. You have $version.';
  }

  @override
  String ready(String version) {
    return 'Ferret $version is ready';
  }

  @override
  String readyOut(String version) {
    return 'Ferret $version is out';
  }

  @override
  String youHave(String version) {
    return 'You have $version';
  }

  @override
  String get packageManager =>
      'Update it with your package manager or software center.';

  @override
  String get manualInstall => 'Download it from the website to install it.';

  @override
  String get install => 'Install';

  @override
  String installTooltip(String version) {
    return 'Download, check and install Ferret $version, then restart';
  }

  @override
  String get whatsNew => 'What\'s new';

  @override
  String whatsNewTitle(String version) {
    return 'What\'s new in Ferret $version';
  }

  @override
  String get noNotes => 'This version came without notes.';

  @override
  String get later => 'Later';

  @override
  String get close => 'Close';

  @override
  String get downloadPage => 'Download page';

  @override
  String get downloadPageTooltip =>
      'Open Ferret\'s download page in your browser';

  @override
  String downloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get downloadingNoSize => 'Downloading…';

  @override
  String get verifying => 'Checking the download…';

  @override
  String get installing => 'Installing…';

  @override
  String get restarting => 'Ferret restarts in a moment.';

  @override
  String get cancel => 'Cancel';

  @override
  String get tryAgain => 'Try again';

  @override
  String get notInstalled => 'Update not installed';

  @override
  String get downloadFailed =>
      'The download didn\'t finish. Check your connection and try again.';

  @override
  String get noFile => 'This release has no file for this system yet.';

  @override
  String get checksumMissing =>
      'This release lists no checksum for the file, so Ferret can\'t check it. Nothing was installed.';

  @override
  String get checksumMismatch =>
      'The download doesn\'t match the checksum on GitHub, so it may be damaged or changed. Nothing was installed.';

  @override
  String get notSigned =>
      'The download isn\'t properly signed. Nothing was installed.';

  @override
  String get wrongPublisher =>
      'The download isn\'t signed by Ferret\'s developer. Nothing was installed.';

  @override
  String get notNotarized =>
      'Apple hasn\'t checked this download (it isn\'t notarized). Nothing was installed.';

  @override
  String get unsignedHere =>
      'This copy of Ferret isn\'t signed, so it can\'t tell who made the update. Install it from the download page.';

  @override
  String get installFailed =>
      'Ferret couldn\'t install the update. Install it from the download page.';

  @override
  String get permissionTitle => 'Allow Ferret to install its update';

  @override
  String get permissionBody =>
      'Android asks once. Ferret only installs its own updates, checked first.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get openSettingsTooltip =>
      'Open Android\'s Install unknown apps switch for Ferret';

  @override
  String get confirmOnPhone => 'Confirm the update in Android\'s prompt.';

  @override
  String get showPrompt => 'Show prompt';

  @override
  String get showPromptTooltip => 'Show Android\'s install prompt again';

  @override
  String get dragTitle => 'Drag Ferret to Applications';

  @override
  String get dragBody =>
      'Ferret can\'t replace itself in that folder without an administrator, so the checked update is open in Finder.';
}
