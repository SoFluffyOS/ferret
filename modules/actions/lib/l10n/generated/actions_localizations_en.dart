// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'actions_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ActionsLocalizationsEn extends ActionsLocalizations {
  ActionsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Computer actions';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get cancel => 'Cancel';

  @override
  String get allowOnce => 'Allow once';

  @override
  String get allowAlways => 'Always allow';

  @override
  String get dontAllow => 'Don\'t allow';

  @override
  String get actionSleep => 'Sleep';

  @override
  String get actionRestart => 'Restart';

  @override
  String get actionShutDown => 'Shut down';

  @override
  String get actionMute => 'Mute or unmute';

  @override
  String get actionVolumeUp => 'Volume up';

  @override
  String get actionVolumeDown => 'Volume down';

  @override
  String get actionVolume => 'Volume';

  @override
  String consentSleep(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Let $device put $_temp0 to sleep?';
  }

  @override
  String consentRestart(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Let $device restart $_temp0?';
  }

  @override
  String consentShutDown(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Let $device shut down $_temp0?';
  }

  @override
  String consentSound(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Let $device change the volume of $_temp0?';
  }

  @override
  String consentCustom(String device, String name, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Let $device run “$name” on $_temp0?';
  }

  @override
  String consentBody(String device) {
    return 'Always allow, and $device does this without asking next time. You can take that back on its page.';
  }

  @override
  String get consentCountsDown =>
      'You get 10 seconds to cancel before it happens.';

  @override
  String get consentCommandLabel => 'It runs exactly this:';

  @override
  String consentCommandNotice(String command) {
    return 'Runs: $command';
  }

  @override
  String countdownRestart(String computer, int seconds) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    String _temp1 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return 'Restarting $_temp0 in $_temp1';
  }

  @override
  String countdownShutDown(String computer, int seconds) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    String _temp1 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return 'Shutting down $_temp0 in $_temp1';
  }

  @override
  String countdownBody(String device) {
    return '$device asked for it. Save your work, or cancel.';
  }

  @override
  String countdownNoticeRestart(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return '$device is restarting $_temp0';
  }

  @override
  String countdownNoticeShutDown(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return '$device is shutting down $_temp0';
  }

  @override
  String get countdownNoticeBody =>
      'It happens in 10 seconds. Cancel to stop it.';

  @override
  String recordTitle(String action, String device) {
    return '$action, asked by $device';
  }

  @override
  String get recordDone => 'Done';

  @override
  String get recordDenied => 'You said no.';

  @override
  String get recordNotAnswered => 'Nobody answered here.';

  @override
  String get recordCancelled => 'Cancelled here.';

  @override
  String get recordFailed => 'It didn\'t work.';

  @override
  String recordExitCode(int code) {
    return 'Ended with code $code.';
  }

  @override
  String recordTimedOut(int seconds) {
    return 'Stopped: it ran longer than $seconds seconds.';
  }

  @override
  String get recordNotStarted =>
      'It couldn\'t start. Check the command in Settings.';

  @override
  String get groupTitle => 'Power and sound';

  @override
  String groupHint(String device) {
    return 'The first time, $device asks on its own screen.';
  }

  @override
  String get groupYourActions => 'Your actions';

  @override
  String get restartEllipsis => 'Restart…';

  @override
  String get shutDownEllipsis => 'Shut down…';

  @override
  String confirmRestartTitle(String device) {
    return 'Restart $device?';
  }

  @override
  String confirmRestartBody(String device) {
    return 'It counts down 10 seconds first, and anyone at $device can cancel. Ferret reconnects once it\'s back.';
  }

  @override
  String confirmShutDownTitle(String device) {
    return 'Shut down $device?';
  }

  @override
  String confirmShutDownBody(String device) {
    return 'It counts down 10 seconds first, and anyone at $device can cancel. After it\'s off, Ferret can\'t reach it until someone turns it on.';
  }

  @override
  String outAsking(String device, String action) {
    return 'Asking $device: $action…';
  }

  @override
  String outAskingDetail(String device) {
    return 'If it asks, answer on $device.';
  }

  @override
  String outCountingDown(String device) {
    return '$device counts down 10 seconds first.';
  }

  @override
  String outSleep(String device) {
    return '$device is going to sleep';
  }

  @override
  String outRestart(String device) {
    return '$device is restarting';
  }

  @override
  String outShutDown(String device) {
    return '$device is shutting down';
  }

  @override
  String outCustom(String device, String name) {
    return '$device ran “$name”';
  }

  @override
  String outDenied(String device) {
    return '$device said no';
  }

  @override
  String outNotAnswered(String device) {
    return 'Nobody answered on $device';
  }

  @override
  String get outNotAnsweredDetail =>
      'The question stays on its screen for a minute. Try again when someone is there.';

  @override
  String outBusy(String device) {
    return '$device is busy with another request';
  }

  @override
  String outTurnedOff(String device) {
    return 'Actions are off on $device';
  }

  @override
  String get outTurnedOffDetail => 'Turn them on there: Settings → Control.';

  @override
  String outUnknown(String device) {
    return '$device no longer has that action';
  }

  @override
  String outFailed(String device) {
    return 'It didn\'t work on $device';
  }

  @override
  String outFailedCode(String name, int code) {
    return '“$name” ended with code $code there.';
  }

  @override
  String outCancelled(String device) {
    return 'Cancelled on $device';
  }

  @override
  String outTimedOut(String name, String device) {
    return '“$name” ran too long on $device';
  }

  @override
  String get outTimedOutDetail => 'It was stopped there.';

  @override
  String settingsEnabled(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Let your devices run actions on $_temp0';
  }

  @override
  String get settingsEnabledBody =>
      'Sleep, restart, shut down, volume, and your own actions. Each device asks here the first time.';

  @override
  String get settingsPerDevice =>
      'What a device may do without asking is on its page.';

  @override
  String get yourActionsTitle => 'Your actions';

  @override
  String get yourActionsEmpty =>
      'A command, a script or a shortcut of yours, under a name. Your devices only ever see the name.';

  @override
  String get addAction => 'Add action';

  @override
  String get editAction => 'Edit';

  @override
  String get editNewTitle => 'New action';

  @override
  String get editTitle => 'Edit action';

  @override
  String get editName => 'Name';

  @override
  String get editNameHint => 'Good night';

  @override
  String get editCommand => 'Command, script or shortcut';

  @override
  String editCommandHelp(int seconds) {
    return 'It runs as you, without a shell: no pipes, no &&. Put those in a script and give its path. It\'s stopped after $seconds seconds.';
  }

  @override
  String get editCommandChanged => 'A new command asks every device again.';

  @override
  String get save => 'Save';

  @override
  String get remove => 'Remove';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'Nothing ran yet.';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get summaryOff => 'Off';

  @override
  String get summaryOn => 'Asks first';

  @override
  String summaryOwn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of your own',
      one: '1 of your own',
    );
    return '$_temp0';
  }

  @override
  String permissionSleep(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Put $_temp0 to sleep without asking';
  }

  @override
  String permissionRestart(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Restart $_temp0 without asking';
  }

  @override
  String permissionShutDown(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Shut down $_temp0 without asking';
  }

  @override
  String permissionSound(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Change the volume of $_temp0 without asking';
  }

  @override
  String permissionCustom(String name) {
    return 'Run “$name” without asking';
  }

  @override
  String healthOffers(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions',
      one: '1 action',
    );
    return '$_temp0. $device asks the first time.';
  }

  @override
  String healthRemoteOff(String device) {
    return 'Actions are off on $device';
  }

  @override
  String healthRemoteOffHelp(String device) {
    return 'On $device, open Settings → Control and turn on Computer actions.';
  }

  @override
  String get healthHostAsks => 'Asks you here the first time';

  @override
  String healthHostOff(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Actions are off on $_temp0';
  }

  @override
  String get healthHostOffHelp =>
      'Turn on Computer actions in Settings → Control.';

  @override
  String get leaveTitle => 'Lock when your phone leaves';

  @override
  String leaveSwitch(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Lock $_temp0 when $device leaves';
  }

  @override
  String leaveSwitchBody(String device, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'When $device drops off the Wi-Fi and stays gone for $_temp0.';
  }

  @override
  String get leaveAfter => 'Lock after';

  @override
  String leaveMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get leaveNote =>
      'It waits until nobody has touched the keyboard or mouse for a minute, then gives you 10 seconds to cancel. It never unlocks. Pausing Ferret on the phone isn\'t leaving.';

  @override
  String leaveNoPhones(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Pair an Android phone to lock $_temp0 when it leaves. iPhone can\'t: iOS stops Ferret in the background, so it would look gone all the time.';
  }

  @override
  String leaveCountdownTitle(String computer, int seconds) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    String _temp1 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return 'Locking $_temp0 in $_temp1';
  }

  @override
  String leaveCountdownBody(String device) {
    return '$device left. Cancel if you\'re still here.';
  }

  @override
  String leaveNoticeTitle(String computer, String device) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Locking $_temp0: $device left';
  }

  @override
  String get leaveNoticeBody => 'Cancel to keep it unlocked.';

  @override
  String leaveLocked(String computer, String device) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Locked $_temp0: $device left';
  }

  @override
  String leaveLockedDetail(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'Gone for $_temp0, with nobody at the keyboard';
  }

  @override
  String leaveCancelled(String device) {
    return 'Stayed unlocked after $device left';
  }

  @override
  String get leaveCancelledDetail => 'You cancelled the lock';

  @override
  String leaveFailed(String computer, String device) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Couldn\'t lock $_temp0 after $device left';
  }

  @override
  String get leaveFailedDetail => 'The system said no. Lock it by hand.';

  @override
  String leavePermissionDetail(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return 'After $_temp0 away, when nobody is at the keyboard';
  }
}
