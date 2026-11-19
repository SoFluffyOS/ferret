// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'scripting_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ScriptingLocalizationsEn extends ScriptingLocalizations {
  ScriptingLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Scripts';

  @override
  String noticeTitle(String title, String device) {
    return '$title · $device';
  }

  @override
  String noticeCover(String device) {
    return 'Notice from a script on $device';
  }

  @override
  String permissionLabel(String device) {
    return 'Let scripts on $device show notices here';
  }

  @override
  String get permissionDetail =>
      'For ferret-cli notify. Off until you turn it on.';

  @override
  String settingsIntro(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Scripts on $_temp0 can follow what Ferret does with ferret-cli watch, and react to it with hooks: an executable named after an event, such as device.connected, in the folder below.';
  }

  @override
  String get hooksFolder => 'Hooks folder';

  @override
  String get hooksNone => 'No hooks yet.';

  @override
  String hooksActive(String events) {
    return 'Hooks that run: $events';
  }

  @override
  String get hooksPrivacy =>
      'Hooks never get copied text or notification text, and get no names while previews from that device are off.';

  @override
  String get copyPath => 'Copy path';

  @override
  String get checkAgain => 'Check again';

  @override
  String failureTitle(String source) {
    return '$source couldn\'t do that';
  }

  @override
  String failureNotConnected(String device) {
    return '$device isn\'t connected right now.';
  }

  @override
  String failureUnknownDevice(String device) {
    return 'No paired device is called $device.';
  }

  @override
  String failureAmbiguous(String device) {
    return 'Several devices fit $device. Use more of its name.';
  }

  @override
  String failureNotAllowed(String device) {
    return '$device doesn\'t take notices from scripts here yet.';
  }

  @override
  String failureUnknownAction(String device) {
    return '$device has no action by that name.';
  }

  @override
  String get failureOther => 'It didn\'t work. Check the action\'s settings.';
}
