// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'remote_input_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class RemoteInputLocalizationsEn extends RemoteInputLocalizations {
  RemoteInputLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Remote input';

  @override
  String get useAsTouchpad => 'Use as touchpad';

  @override
  String get back => 'Back';

  @override
  String consentTitle(String device) {
    return 'Let $device control this computer?';
  }

  @override
  String consentBody(String device) {
    return '$device can move the pointer, click and type here until you stop it. You\'ll see it the whole time.';
  }

  @override
  String get allowOnce => 'Allow once';

  @override
  String get allowAlways => 'Always';

  @override
  String get dontAllow => 'Don\'t allow';

  @override
  String controlledBy(String device) {
    return 'Controlled by $device';
  }

  @override
  String controlledSince(String time) {
    return 'Since $time. It can move the pointer and type.';
  }

  @override
  String get stop => 'Stop';

  @override
  String get activeNoticeBody => 'Tap Stop to take back control.';

  @override
  String permissionTitle(String device) {
    return '$device can\'t control this computer yet';
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
  String auditLine(String device, int minutes, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      one: '1 min',
      zero: 'less than a minute',
    );
    return '$device controlled this computer for $_temp0 at $time';
  }

  @override
  String get settingsEnabled => 'Let my phones control this computer';

  @override
  String get settingsEnabledBody =>
      'A phone becomes its touchpad and keyboard. Each phone asks you first.';

  @override
  String get statusReadyQuartz => 'Ready. Uses Accessibility access.';

  @override
  String get statusReadySendInput =>
      'Ready. Apps running as administrator can\'t be controlled.';

  @override
  String get statusReadyUinput => 'Ready. Uses a virtual input device.';

  @override
  String get statusReadyXdotool =>
      'Ready. Uses xdotool, which works on X11 only.';

  @override
  String get statusReadyYdotool => 'Ready. Uses ydotool.';

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
  String get statusFailed =>
      'Ferret couldn\'t check whether it may control this computer.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get settingsAllowedTitle => 'Always allowed';

  @override
  String get settingsAllowedEmpty =>
      'No device yet. Pick Always when a phone asks.';

  @override
  String get revoke => 'Revoke';

  @override
  String get settingsHistoryTitle => 'History';

  @override
  String get settingsHistoryEmpty => 'No device controlled this computer yet.';

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
    return 'Click Allow on $device. Pick Always and it won\'t ask again.';
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
    return '$device needs Accessibility access first. Open Ferret on $device to allow it.';
  }

  @override
  String deniedUnsupported(String device) {
    return '$device can\'t be controlled yet. Open Ferret\'s settings on $device to see why.';
  }

  @override
  String deniedTurnedOff(String device) {
    return 'Remote input is off on $device. Turn it on in Ferret\'s settings there.';
  }

  @override
  String deniedVersion(String device) {
    return '$device runs an older Ferret. Update it, then try again.';
  }

  @override
  String stoppedOnHost(String device) {
    return 'Someone stopped it on $device.';
  }

  @override
  String get stoppedIdle => 'Stopped after a long time without input.';

  @override
  String stoppedRevoked(String device) {
    return '$device turned remote input off for this phone.';
  }

  @override
  String stoppedFailed(String device) {
    return '$device can\'t inject input anymore. Check Accessibility access there.';
  }

  @override
  String lostConnection(String device) {
    return 'Lost the connection to $device.';
  }

  @override
  String unreachable(String device) {
    return '$device didn\'t answer. Is Ferret open on it?';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String controllingTitle(String device) {
    return 'Controlling $device';
  }

  @override
  String get controllingBody => 'Your phone is its touchpad.';

  @override
  String get openTouchpad => 'Open touchpad';

  @override
  String healthNeedsPermission(String device) {
    return '$device needs Accessibility access for remote input';
  }

  @override
  String healthUnsupported(String device) {
    return '$device can\'t be controlled';
  }

  @override
  String healthTurnedOff(String device) {
    return 'Remote input is off on $device';
  }
}
