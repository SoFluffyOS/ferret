/// How this computer injects input.
enum InjectorBackend {
  /// CGEvent on macOS.
  quartz,

  /// SendInput on Windows.
  sendInput,

  /// A virtual device through `/dev/uinput` on Linux.
  uinput,

  /// The `xdotool` command (X11).
  xdotool,

  /// The `ydotool` command (Wayland and X11, through its daemon).
  ydotool,
}

enum InjectorState {
  ready,

  /// The person has to allow it first, such as Accessibility on macOS.
  needsPermission,

  /// There is no way to inject input here.
  unavailable,
}

/// Why input can't be injected.
enum UnavailableReason {
  /// Phones and tablets are controllers only.
  platform,

  /// Linux without uinput access, xdotool or ydotool.
  noLinuxBackend,

  /// Linux with ydotool, but its daemon `ydotoold` isn't running.
  ydotoolNotRunning,

  /// The platform call failed.
  failed,
}

/// Whether this device can inject input right now, and how.
class InjectorStatus {
  const InjectorStatus.ready(InjectorBackend this.backend)
    : state = .ready,
      reason = null;

  const InjectorStatus.needsPermission(InjectorBackend this.backend)
    : state = .needsPermission,
      reason = null;

  const InjectorStatus.unavailable(UnavailableReason this.reason)
    : state = .unavailable,
      backend = null;

  final InjectorState state;
  final InjectorBackend? backend;
  final UnavailableReason? reason;

  bool get isReady => state == .ready;

  @override
  bool operator ==(Object other) =>
      other is InjectorStatus &&
      other.state == state &&
      other.backend == backend &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(state, backend, reason);

  @override
  String toString() => 'InjectorStatus($state, $backend, $reason)';
}
