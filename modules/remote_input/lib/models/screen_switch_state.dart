import 'package:remote_input/models/outgoing_control.dart';

/// Where this Mac's keyboard and mouse are.
enum ScreenSwitchPhase {
  /// Here, on this Mac.
  home,

  /// Asking another computer, whose owner may have to answer first.
  asking,

  /// On another computer; ⌃⌥⎋ brings them back.
  away,
}

/// Why a switch didn't happen, or why the keyboard and mouse came back.
enum ScreenSwitchProblem {
  /// No connected computer takes them.
  noComputer,

  /// Input Monitoring or Accessibility is off on this Mac.
  needsAccess,

  /// A password field holds secure input, which hides keys from Ferret.
  secureInput,

  /// macOS wouldn't let Ferret hold the keyboard and mouse.
  captureFailed,

  /// The other computer said no; see [ScreenSwitchState.denial].
  denied,

  /// The other computer went away.
  lostConnection,

  /// Someone on the other computer stopped it, or it went idle.
  stopped,
}

class ScreenSwitchState {
  const ScreenSwitchState({
    required this.phase,
    this.deviceId,
    this.deviceName = '',
    this.problem,
    this.denial,
    this.secureInputHolder,
    this.at,
  });

  static const home = ScreenSwitchState(phase: .home);

  final ScreenSwitchPhase phase;

  /// The computer asked or used, or the one a [problem] is about.
  final String? deviceId;
  final String deviceName;
  final ScreenSwitchProblem? problem;
  final OutgoingDenial? denial;

  /// The app that turned on secure input, such as a password manager,
  /// when macOS says which.
  final String? secureInputHolder;

  /// When this state began.
  final DateTime? at;

  bool get isAway => phase == .away;
}
