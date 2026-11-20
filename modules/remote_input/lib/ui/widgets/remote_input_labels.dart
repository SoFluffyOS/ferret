import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:intl/intl.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';

/// Words for where remote input stands, on either side.
extension RemoteInputLabels on RemoteInputLocalizations {
  /// Why an attempt to control a device didn't work, or null while it is
  /// still going.
  String? outcome(OutgoingControl control) {
    final name = control.deviceName;
    return switch (control.phase) {
      .requesting || .waitingForConsent || .active => null,
      .denied => _denial(control.denial, name, control.host),
      .stopped => _stop(control.stop, name, control.host),
      .lostConnection => lostConnection(name),
      .unreachable => unreachable(name),
    };
  }

  /// Why this Mac's keyboard and mouse didn't go, or came back: the line.
  String screenProblemTitle(ScreenSwitchState state) {
    final name = state.deviceName;
    return switch (state.problem) {
      .noComputer => screenNoComputer,
      .needsAccess => screenNeedsAccess,
      .secureInput => switch (state.secureInputHolder) {
        final app? => screenSecureInputApp(app),
        null => screenSecureInput,
      },
      .captureFailed => screenCaptureFailed(ThisComputer.here),
      .denied => screenDenied(name),
      .lostConnection => screenLost(name),
      .stopped => screenStopped(name),
      null => '',
    };
  }

  /// What to do about [screenProblemTitle], or where the keys are now.
  String screenProblemBody(ScreenSwitchState state) {
    final name = state.deviceName;
    return switch (state.problem) {
      .noComputer => screenNoComputerBody,
      .needsAccess => screenNeedsAccessBody,
      .secureInput => switch (state.secureInputHolder) {
        final app? => screenSecureInputAppBody(app),
        null => screenSecureInputBody(ThisComputer.here),
      },
      .denied => _denial(state.denial, name, state.host),
      .captureFailed ||
      .lostConnection ||
      .stopped ||
      null => screenBackHere(ThisComputer.here),
    };
  }

  String _denial(
    OutgoingDenial? denial,
    String name,
    HostKind? host,
  ) => switch (denial) {
    .timeout => deniedTimeout(name),
    .busy => deniedBusy(name),
    .needsPermission => deniedNeedsPermission(name, hostKey(host)),
    .unsupported => deniedUnsupported(name, hostKey(host)),
    .turnedOff => deniedTurnedOff(name),
    .version => deniedVersion(name),
    .denied || null => deniedDenied(name),
  };

  String _stop(OutgoingStop? stop, String name, HostKind? host) =>
      switch (stop) {
        .idle => stoppedIdle,
        .revoked => stoppedRevoked(name, ThisComputer.handheld),
        .failed => stoppedFailed(name, hostKey(host)),
        .stoppedOnHost || null => stoppedOnHost(name),
      };

  /// The `host` select key in the strings: mac, windows, linux, or other
  /// when the kind of computer isn't known.
  String hostKey(HostKind? host) => host?.name ?? 'other';

  /// "Pixel controlled this computer for 4 min at 21:10".
  String audit(ControlRecord record) => auditLine(
    record.deviceName,
    record.duration.inMinutes,
    _time(record.startedAt),
    ThisComputer.here,
  );

  String since(DateTime startedAt) => controlledSince(_time(startedAt));

  /// intl throws for a locale whose date symbols were never loaded; the
  /// default format beats no line at all.
  String _time(DateTime at) {
    try {
      return DateFormat.jm(localeName).format(at);
    } on Object {
      return DateFormat.jm().format(at);
    }
  }

  /// What this computer uses to inject input, or what is missing.
  String statusLine(InjectorStatus status) => switch (status) {
    InjectorStatus(state: .ready, backend: .quartz) => statusReadyQuartz,
    InjectorStatus(state: .ready, backend: .sendInput) => statusReadySendInput,
    InjectorStatus(state: .ready, backend: .uinput) => statusReadyUinput,
    InjectorStatus(state: .ready, backend: .xdotool) => statusReadyXdotool,
    InjectorStatus(state: .ready) => statusReadyYdotool,
    InjectorStatus(state: .needsPermission) => statusNeedsPermission,
    InjectorStatus(reason: .noLinuxBackend) => statusNoLinuxBackend,
    InjectorStatus(reason: .ydotoolNotRunning) => statusYdotoolNotRunning,
    _ => statusFailed,
  };

  /// How to fix a missing ability, or null when there is nothing to do.
  String? statusFix(InjectorStatus status) => switch (status) {
    InjectorStatus(state: .needsPermission) => statusNeedsPermissionBody,
    InjectorStatus(reason: .noLinuxBackend) => statusNoLinuxBackendBody,
    InjectorStatus(reason: .ydotoolNotRunning) => statusYdotoolNotRunningBody,
    InjectorStatus(state: .unavailable) => statusFailedBody(ThisComputer.here),
    _ => null,
  };

  /// The name of [modifier] on the controlled computer's keyboard.
  String modifierLabel(KeyModifier modifier, HostKind host) =>
      switch ((modifier, host)) {
        (.shift, _) => modShift,
        (.control, _) => modControl,
        (.alt, .mac) => modAltMac,
        (.alt, _) => modAlt,
        (.meta, .mac) => modMetaMac,
        (.meta, .windows) => modMeta,
        (.meta, .linux) => modMetaLinux,
      };
}
