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
    return '$device didn\'t answer. Check that Ferret is running there, then try again.';
  }

  @override
  String deviceNotSharing(String device) {
    return '$device stopped sharing its media. Turn on Share my media there.';
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
  String get accessAndroid =>
      'Ferret needs Notification access to see what plays on this phone. It only reads media controls here.';

  @override
  String get accessMacos =>
      'macOS asks once to let Ferret control Music and Spotify.';

  @override
  String get accessDenied =>
      'Ferret can\'t control Music or Spotify yet. Allow it in System Settings, Privacy & Security, Automation.';

  @override
  String get accessAllow => 'Allow';

  @override
  String get accessOpenSettings => 'Open settings';

  @override
  String get accessCheckAgain => 'Check again';

  @override
  String get limitMacos =>
      'On a Mac, Ferret sees Music and Spotify. macOS doesn\'t let apps see other players.';

  @override
  String get limitIos =>
      'iPhone doesn\'t let apps see what other apps play. You can still see and control media on your other devices.';

  @override
  String get limitWindows =>
      'Ferret sees players that show in the Windows media controls. Volume stays on this PC.';

  @override
  String get limitLinux =>
      'Ferret sees players that support MPRIS, which most Linux players do.';
}
