// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'remote_input_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class RemoteInputLocalizationsEn extends RemoteInputLocalizations {
  RemoteInputLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Control';

  @override
  String get useAsTouchpad => 'Control';

  @override
  String get back => 'Back';

  @override
  String consentTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Let $device control $_temp0?';
  }

  @override
  String consentBody(String device) {
    return '$device can move the pointer, click and type here until you stop it. You\'ll see it the whole time.';
  }

  @override
  String get allowOnce => 'Allow once';

  @override
  String get allowAlways => 'Always allow';

  @override
  String get dontAllow => 'Don\'t allow';

  @override
  String controlledBy(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return '$device is controlling $_temp0';
  }

  @override
  String controlledSince(String time) {
    return 'Since $time. It can move the pointer and type.';
  }

  @override
  String get stop => 'Stop control';

  @override
  String activityControlling(String device, String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return '$device is controlling $_temp0';
  }

  @override
  String get activityStop => 'Stop';

  @override
  String activityControlled(String device, String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return '$device controlled $_temp0';
  }

  @override
  String activityControlledFor(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'For $minutes min',
      one: 'For 1 min',
      zero: 'For less than a minute',
    );
    return '$_temp0';
  }

  @override
  String activeNoticeBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Tap Stop control to take $_temp0 back.';
  }

  @override
  String permissionTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return '$device can\'t control $_temp0 yet';
  }

  @override
  String permissionBody(String device) {
    return 'Allow Ferret in Accessibility settings, then try again on $device.';
  }

  @override
  String get openSettings => 'Open Settings';

  @override
  String get dismiss => 'Dismiss';

  @override
  String auditLine(String device, int minutes, String time, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
      zero: 'less than a minute',
    );
    return '$device controlled $_temp0 for $_temp1 at $time';
  }

  @override
  String settingsEnabled(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Let my phones control $_temp0';
  }

  @override
  String get settingsEnabledBody =>
      'A phone becomes its touchpad and keyboard. Each phone asks you first.';

  @override
  String get statusReadyQuartz => 'On. Uses Accessibility access.';

  @override
  String get statusReadySendInput =>
      'On. Apps running as administrator can\'t be controlled.';

  @override
  String get statusReadyUinput => 'On. Uses a virtual input device.';

  @override
  String get statusReadyXdotool => 'On. Uses xdotool, which works on X11 only.';

  @override
  String get statusReadyYdotool => 'On. Uses ydotool.';

  @override
  String get statusNeedsPermission => 'Accessibility access is off';

  @override
  String get statusNeedsPermissionBody =>
      'macOS asks before any app may move the pointer or type. Turn on Ferret in the list, then come back.';

  @override
  String get allowAccess => 'Allow access';

  @override
  String get statusNoLinuxBackend => 'This computer can\'t be controlled yet';

  @override
  String get statusNoLinuxBackendBody =>
      'Ferret needs write access to /dev/uinput, or xdotool (X11) or ydotool (Wayland). Install one with your package manager, then check again.';

  @override
  String get statusYdotoolNotRunning =>
      'ydotool is installed, but its service isn\'t running';

  @override
  String get statusYdotoolNotRunningBody =>
      'Start the ydotoold service, then check again.';

  @override
  String get statusFailed => 'Not checked yet';

  @override
  String statusFailedBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Ferret doesn\'t know yet whether it may control $_temp0. Check again.';
  }

  @override
  String get checkAgain => 'Check again';

  @override
  String settingsPerDevice(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'To let one phone control $_temp0 without asking, open the phone from Home.';
  }

  @override
  String get settingsHostTitle => 'Pointer and keyboard';

  @override
  String get settingsTouchpadTitle => 'Touchpad';

  @override
  String get summaryOn => 'On';

  @override
  String get summaryOff => 'Off';

  @override
  String get summaryNeedsAccess => 'Needs access';

  @override
  String get summaryUnavailable => 'Not available yet';

  @override
  String permissionAlways(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Control $_temp0 without asking';
  }

  @override
  String get permissionAlwaysDetail =>
      'You still see it the whole time, with Stop control.';

  @override
  String get permissionAlwaysOff =>
      'Control is off. Turn it on in Settings → Control.';

  @override
  String get settingsHistoryTitle => 'History';

  @override
  String settingsHistoryEmpty(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'No device controlled $_temp0 yet.';
  }

  @override
  String get clearHistory => 'Clear history';

  @override
  String get settingsSpeed => 'Touchpad speed';

  @override
  String get settingsSpeedBody =>
      'How far the pointer moves for the same finger move.';

  @override
  String get settingsNaturalScroll => 'Natural scrolling';

  @override
  String get settingsNaturalScrollBody =>
      'Move two fingers up to scroll down, like on your phone\'s screen.';

  @override
  String requesting(String device) {
    return 'Asking $device…';
  }

  @override
  String waitingTitle(String device) {
    return 'Waiting for $device';
  }

  @override
  String waitingBody(String device) {
    return 'On $device: click Allow once. Pick Always allow and it won\'t ask again.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get touchpadHint =>
      'One finger moves. Tap to click, hold to right-click. Two fingers scroll. Tap, then slide to drag.';

  @override
  String get leftButton => 'Left click';

  @override
  String get rightButton => 'Right click';

  @override
  String get keyboardHint => 'Type here';

  @override
  String get showKeyboard => 'Keyboard';

  @override
  String get hideKeyboard => 'Hide keyboard';

  @override
  String get keyEscape => 'Esc';

  @override
  String get keyTab => 'Tab';

  @override
  String get keyEnter => 'Enter';

  @override
  String get keyBackspace => 'Backspace';

  @override
  String get keyLeft => 'Left';

  @override
  String get keyRight => 'Right';

  @override
  String get keyUp => 'Up';

  @override
  String get keyDown => 'Down';

  @override
  String get mediaPrevious => 'Previous';

  @override
  String get mediaPlayPause => 'Play or pause';

  @override
  String get mediaNext => 'Next';

  @override
  String get volumeDown => 'Volume down';

  @override
  String get volumeMute => 'Mute';

  @override
  String get volumeUp => 'Volume up';

  @override
  String get modShift => 'Shift';

  @override
  String get modControl => 'Ctrl';

  @override
  String get modAlt => 'Alt';

  @override
  String get modAltMac => 'Option';

  @override
  String get modMeta => 'Win';

  @override
  String get modMetaMac => 'Cmd';

  @override
  String get modMetaLinux => 'Super';

  @override
  String deniedDenied(String device) {
    return '$device said no.';
  }

  @override
  String deniedTimeout(String device) {
    return 'Nobody answered on $device.';
  }

  @override
  String deniedBusy(String device) {
    return 'Another device controls $device right now.';
  }

  @override
  String deniedNeedsPermission(String device) {
    return '$device needs Accessibility access first. On $device: open Ferret and allow it.';
  }

  @override
  String deniedUnsupported(String device) {
    return '$device can\'t be controlled yet. On $device: open Ferret → Settings → Control to see why.';
  }

  @override
  String deniedTurnedOff(String device) {
    return 'Control is off on $device. On $device: open Ferret → Settings → Control and turn it on.';
  }

  @override
  String deniedVersion(String device) {
    return '$device runs an older Ferret. Update Ferret on $device, then try again.';
  }

  @override
  String stoppedOnHost(String device) {
    return 'Someone stopped it on $device.';
  }

  @override
  String get stoppedIdle => 'Stopped after a long time without input.';

  @override
  String stoppedRevoked(String device) {
    return '$device no longer lets this phone control it.';
  }

  @override
  String stoppedFailed(String device) {
    return '$device can\'t move the pointer or type anymore. On $device: check Accessibility access.';
  }

  @override
  String lostConnection(String device) {
    return 'Lost the connection to $device.';
  }

  @override
  String unreachable(String device) {
    return '$device didn\'t answer. On $device: open Ferret.';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String healthAsksFirst(String device) {
    return 'Asks on $device first';
  }

  @override
  String healthAlways(String device) {
    return 'Allowed on $device without asking';
  }

  @override
  String healthControlling(String device) {
    return 'Controlling $device now';
  }

  @override
  String healthNeedsPermissionHelp(String device) {
    return 'On $device: open Ferret → Settings → Control and click Allow access.';
  }

  @override
  String healthUnsupportedHelp(String device) {
    return 'On $device: open Ferret → Settings → Control to see what it needs.';
  }

  @override
  String healthTurnedOffHelp(String device, String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'On $device: open Ferret → Settings → Control and turn on Let my phones control $_temp0.';
  }

  @override
  String healthVersion(String device) {
    return 'Needs a Ferret update on $device';
  }

  @override
  String healthVersionHelp(String device) {
    return 'On $device: update Ferret.';
  }

  @override
  String healthNotAnswering(String device) {
    return '$device didn\'t answer last time';
  }

  @override
  String healthNotAnsweringHelp(String device) {
    return 'On $device: open Ferret.';
  }

  @override
  String healthHostAsks(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Asks before it controls $_temp0';
  }

  @override
  String healthHostAlways(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'May control $_temp0 without asking';
  }

  @override
  String healthHostControlling(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Controlling $_temp0 now';
  }

  @override
  String healthHostOff(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Off on $_temp0';
  }

  @override
  String healthHostOffHelp(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Open Settings → Control and turn on Let my phones control $_temp0.';
  }

  @override
  String healthHostNeedsAccess(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Needs Accessibility access on $_temp0';
  }

  @override
  String get healthHostNeedsAccessHelp =>
      'Open Settings → Control and click Allow access.';

  @override
  String get healthHostUnavailable => 'Can\'t be controlled yet';

  @override
  String get healthHostUnavailableHelp =>
      'Open Settings → Control to see what it needs.';

  @override
  String healthNeedsPermission(String device) {
    return 'Needs Accessibility access on $device';
  }

  @override
  String healthUnsupported(String device) {
    return '$device can\'t be controlled';
  }

  @override
  String healthTurnedOff(String device) {
    return 'Off on $device';
  }

  @override
  String lockConsentTitle(String device, String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Let $device lock $_temp0?';
  }

  @override
  String lockConsentBody(String device) {
    return '$device asks to lock the screen now. Always allow, and it locks right away next time.';
  }

  @override
  String lockDevice(String device) {
    return 'Lock $device';
  }

  @override
  String lockAsking(String device) {
    return 'Locking $device…';
  }

  @override
  String lockAskingDetail(String device) {
    return 'If it asks, answer on $device.';
  }

  @override
  String lockLocked(String device) {
    return 'Locked $device';
  }

  @override
  String lockDenied(String device) {
    return '$device said no to locking';
  }

  @override
  String lockTimedOut(String device) {
    return '$device didn\'t answer';
  }

  @override
  String get lockTimedOutDetail =>
      'Nobody said yes on it in time, or it went offline.';

  @override
  String lockBusy(String device) {
    return '$device is asking about another device';
  }

  @override
  String lockTurnedOff(String device) {
    return 'Control is off on $device';
  }

  @override
  String get lockTurnedOffDetail => 'Turn it on there in Settings → Control.';

  @override
  String lockFailed(String device) {
    return '$device couldn\'t lock';
  }

  @override
  String permissionLock(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'this Mac',
        'windows': 'this PC',
        'other': 'this computer',
      },
    );
    return 'Lock $_temp0 without asking';
  }

  @override
  String get permissionLockDetail =>
      'Lock from the phone, with no question here.';

  @override
  String presentOn(String device) {
    return 'Present on $device';
  }

  @override
  String get presentTitle => 'Presentation';

  @override
  String get presentNext => 'Next';

  @override
  String get presentPrevious => 'Previous';

  @override
  String get presentBlackScreen => 'Black screen';

  @override
  String get presentShowSlides => 'Show slides';

  @override
  String get presentTimerHint => 'The timer starts with the first slide';

  @override
  String get presentRestartTimer => 'Tap the time to start over';

  @override
  String get presentWorksWith =>
      'Works with PowerPoint, Keynote, Google Slides and PDFs in full screen, like a clicker.';
}
