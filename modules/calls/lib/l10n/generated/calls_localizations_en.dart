// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'calls_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class CallsLocalizationsEn extends CallsLocalizations {
  CallsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Calls';

  @override
  String get back => 'Back';

  @override
  String get unknownCaller => 'Unknown caller';

  @override
  String incomingOn(String device) {
    return 'Incoming call on $device';
  }

  @override
  String callingOn(String device) {
    return 'Calling from $device';
  }

  @override
  String onCallOn(String device) {
    return 'On a call on $device';
  }

  @override
  String onHoldOn(String device) {
    return 'On hold on $device';
  }

  @override
  String get answer => 'Answer';

  @override
  String get decline => 'Decline';

  @override
  String get hangUp => 'Hang up';





  @override
  String get silence => 'Silence';

  @override
  String get silenced => 'Ringer silenced';

  @override
  String audioStays(String device) {
    return 'Audio stays on $device for now. Talk on $device or its headset.';
  }

  @override
  String get outcomeNoCall => 'That call is already over.';

  @override
  String outcomeDisabled(String device) {
    return 'Calls are off on $device. On $device: Ferret → Do more → Calls.';
  }

  @override
  String outcomePermission(String device) {
    return '$device hasn\'t allowed this yet. On $device: Ferret → Settings → To your computer, then allow it under Calls.';
  }

  @override
  String outcomeUnsupported(String device) {
    return '$device\'s Android version can\'t do this.';
  }

  @override
  String get outcomeInvalidNumber => 'That doesn\'t look like a phone number.';

  @override
  String outcomeFailed(String device) {
    return '$device couldn\'t do that. Try it on $device.';
  }

  @override
  String outcomeUnreachable(String device) {
    return '$device didn\'t answer. Check that it\'s connected.';
  }

  @override
  String noticeIncomingBody(String device) {
    return 'Incoming call · $device';
  }

  @override
  String get noticeMissedTitle => 'Missed call';

  @override
  String noticeMissedBody(String caller, String device) {
    return '$caller · $device';
  }

  @override
  String get callAction => 'Call…';

  @override
  String dialerTitle(String device) {
    return 'Call from $device';
  }

  @override
  String get numberLabel => 'Phone number';

  @override
  String get numberHint => '+1 555 0100';

  @override
  String get call => 'Call';

  @override
  String callStarted(String device) {
    return '$device is calling. Audio stays on $device for now.';
  }

  @override
  String get recentCalls => 'Recent calls';

  @override
  String get recentEmpty => 'No recent calls.';

  @override
  String get recentLoading => 'Loading recent calls…';

  @override
  String logUnreachable(String device) {
    return '$device didn\'t answer. Check that it\'s connected.';
  }

  @override
  String logPermission(String device) {
    return '$device doesn\'t let Ferret read its recent calls. On $device: Ferret → Settings → To your computer, then allow Call logs under Calls.';
  }

  @override
  String logDisabled(String device) {
    return 'Calls are off on $device. On $device: Ferret → Do more → Calls.';
  }

  @override
  String get retry => 'Try again';

  @override
  String get typeIncoming => 'Incoming';

  @override
  String get typeOutgoing => 'Outgoing';

  @override
  String get typeMissed => 'Missed';

  @override
  String get typeRejected => 'Declined';

  @override
  String get privateNumber => 'Private number';

  @override
  String get explainer => 'See who\'s calling and answer from your computer.';

  @override
  String get explainerDetail =>
      'Android will ask for Phone, Call logs and Contacts. Calls only go to your own paired devices. Audio stays on this phone for now.';

  @override
  String get turnOn => 'Turn on';

  @override
  String get turnOff => 'Turn off';

  @override
  String get setUp => 'Set up';

  @override
  String get fix => 'Fix';

  @override
  String get phoneHomePaused =>
      'Calls are on, but Ferret can\'t see this phone\'s calls yet.';

  @override
  String get permissionOff => 'Ferret can\'t see calls yet';

  @override
  String get permissionStillOff =>
      'Still off. Android won\'t ask again, so allow it in the app\'s settings.';

  @override
  String get permissionHowTo =>
      'Allow Phone so Ferret can tell your computer when a call comes in.';

  @override
  String get permissionHowToSettings =>
      'In the app\'s settings, open Permissions, then Phone, then Allow. Do the same for Call logs and Contacts.';

  @override
  String get allow => 'Allow access';

  @override
  String get allowRest => 'Allow the rest';

  @override
  String get openSettings => 'Open app settings';

  @override
  String get openSettingsFailed =>
      'Couldn\'t open Settings. Open Android Settings, then Apps, then Ferret, then Permissions.';

  @override
  String get ready => 'Your computers see this phone\'s calls';

  @override
  String get capNumbers => 'Who is calling, and recent calls';

  @override
  String get capContacts => 'Names and photos';

  @override
  String get capAnswer => 'Answer, decline and hang up';

  @override
  String get capDial => 'Start calls from your computer';

  @override
  String get audioOnPhone => 'Call audio stays on this phone for now.';

  @override
  String get showIncoming => 'Show incoming calls';

  @override
  String get showIncomingDetail =>
      'A notification with Answer and Decline when your phone rings.';

  @override
  String get settingsAudio =>
      'Call audio stays on the phone for now. Ferret answers the call; you talk on the phone or its headset.';

  @override
  String healthNoAnswer(String device) {
    return '$device didn\'t answer';
  }

  @override
  String healthOff(String device) {
    return 'Off on $device';
  }

  @override
  String get healthNeedsPermission => 'Android turned off Ferret\'s access';

  @override
  String healthLimited(String device) {
    return 'Shows calls. Answer on $device';
  }

  @override
  String get healthOk => 'Answer and decline';

  @override
  String get healthChecking => 'Checking…';

  @override
  String healthOffHelp(String device) {
    return 'On $device: Ferret → Do more → Calls.';
  }

  @override
  String healthNeedsPermissionHelp(String device) {
    return 'On $device: open Ferret and tap Fix.';
  }

  @override
  String get healthLocalOffHelp =>
      'On this phone: Settings → To your computer → Calls.';

  @override
  String healthLocalPushFailedHelp(String device) {
    return 'On $device: open Ferret. The next call shows there.';
  }

  @override
  String get settingsNeedsAccess => 'Needs access';

  @override
  String settingsNeedsAccessOn(String device) {
    return 'Needs access on $device';
  }

  @override
  String get healthLocalOff => 'Off on this phone';

  @override
  String get healthLocalNeedsPermission =>
      'Android turned off Ferret\'s access';

  @override
  String healthLocalPushFailed(String device) {
    return 'The last call didn\'t reach $device';
  }

  @override
  String healthLocalOk(String device) {
    return '$device sees this phone\'s calls';
  }
}
