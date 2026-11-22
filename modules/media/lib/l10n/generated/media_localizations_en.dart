// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'media_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class MediaLocalizationsEn extends MediaLocalizations {
  MediaLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Media';

  @override
  String nowPlayingOn(String device) {
    return 'Now playing on $device';
  }

  @override
  String pausedOn(String device) {
    return 'Paused on $device';
  }

  @override
  String playerOn(String app, String device) {
    return '$app on $device';
  }

  @override
  String get settingsPauseOnCall => 'Pause during calls';

  @override
  String get settingsPauseOnCallBody =>
      'Pauses what plays on this device while a call rings or goes on, and plays it again after.';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get continueHere => 'Continue here';

  @override
  String get continueOpening => 'Opening…';

  @override
  String get continueFromStart => 'Opens from the start';

  @override
  String continueNoLink(String app) {
    return 'This can\'t be opened here. $app didn\'t share a link to it.';
  }

  @override
  String continueOpenFailed(String device) {
    return 'No app here could open it. It keeps playing on $device.';
  }

  @override
  String playerGone(String device) {
    return 'That player closed on $device.';
  }

  @override
  String deviceUnreachable(String device) {
    return '$device didn\'t answer. On $device: open Ferret, then try again.';
  }

  @override
  String deviceNotSharing(String device) {
    return '$device stopped sharing its media. On $device: Settings → Continue & media → Share my media.';
  }

  @override
  String get commandUnsupported => 'This player can\'t do that.';

  @override
  String commandFailed(String device) {
    return 'The player on $device didn\'t respond. Try again.';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get settingsShare => 'Share my media';

  @override
  String get settingsShareBody =>
      'Your other devices see what plays here and can control it.';

  @override
  String get settingsShowRemote => 'Show media from other devices';

  @override
  String get settingsShowRemoteBody =>
      'What plays on your other devices, with controls and Continue here.';

  @override
  String get summaryShowsAndShares => 'Shows and shares what plays';

  @override
  String get summaryShows => 'Shows what your devices play';

  @override
  String get summaryShares => 'Shares what plays here';

  @override
  String get summaryOff => 'Off';

  @override
  String healthUnsupported(String name) {
    return 'Needs a Ferret update on $name';
  }

  @override
  String get healthShowsTheirs => 'Shares what\'s playing.';

  @override
  String get healthNothingPlaying => 'Nothing playing right now';

  @override
  String healthSharesMine(String name, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'this Mac',
        'android': 'this phone',
        'ios': 'this iPhone',
        'windows': 'this PC',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return '$name sees what plays on $_temp0.';
  }

  @override
  String healthShowsAndShares(String name, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'this Mac',
        'android': 'this phone',
        'ios': 'this iPhone',
        'windows': 'this PC',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Shares what\'s playing. $name sees what plays on $_temp0.';
  }

  @override
  String healthLostAccess(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'this Mac',
        'android': 'this phone',
        'ios': 'this iPhone',
        'windows': 'this PC',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Ferret can\'t see what plays on $_temp0';
  }

  @override
  String healthOffHere(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'this Mac',
        'android': 'this phone',
        'ios': 'this iPhone',
        'windows': 'this PC',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Off on $_temp0';
  }

  @override
  String healthNotShared(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'this Mac',
        'android': 'this phone',
        'ios': 'this iPhone',
        'windows': 'this PC',
        'tablet': 'this tablet',
        'other': 'this computer',
      },
    );
    return 'Not shared from $_temp0';
  }

  @override
  String get healthShowHelp =>
      'Settings → Continue & media → Show media from other devices';

  @override
  String get healthShareHelp => 'Settings → Continue & media → Share my media';

  @override
  String accessAndroid(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'this tablet',
        'other': 'this phone',
      },
    );
    return 'Ferret needs Notification access to see what plays on $_temp0. It only reads media controls here.';
  }

  @override
  String get accessMacos =>
      'macOS asks once to let Ferret control Music and Spotify.';

  @override
  String get accessDenied =>
      'Ferret can\'t control Music or Spotify yet. Allow it in System Settings, Privacy & Security, Automation.';

  @override
  String get accessAllow => 'Allow access';

  @override
  String get accessOpenSettings => 'Open settings';

  @override
  String get accessCheckAgain => 'Check again';

  @override
  String get limitMacos =>
      'On a Mac, Ferret sees Music and Spotify. macOS doesn\'t let apps see other players.';

  @override
  String limitIos(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'iPad',
        'other': 'iPhone',
      },
    );
    return '$_temp0 doesn\'t let apps see what other apps play. You can still see and control media on your other devices.';
  }

  @override
  String get limitWindows =>
      'Ferret sees players that show in the Windows media controls. Volume stays on this PC.';

  @override
  String get limitLinux =>
      'Ferret sees players that support MPRIS, which most Linux players do.';

  @override
  String get back => 'Back';

  @override
  String get nowPlayingShort => 'Now playing';

  @override
  String controlMediaOn(String device) {
    return 'Control what plays on $device';
  }
}
