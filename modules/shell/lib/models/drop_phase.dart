/// Where dropping files from the system is at.
sealed class DropPhase {
  const DropPhase();
}

/// Nothing is dragged or being sent.
final class DropIdle extends DropPhase {
  const DropIdle();
}

/// Files are dragged over the window, or were dropped on the menubar icon
/// and wait for a device to be picked ([held]).
final class DropChoosing extends DropPhase {
  const DropChoosing({this.held = false});

  final bool held;
}

/// The files are on their way: [fraction] from 0 to 1.
final class DropSending extends DropPhase {
  const DropSending(this.fraction);

  final double fraction;
}

/// Every file arrived.
final class DropSent extends DropPhase {
  const DropSent();
}

/// Sending stopped; [reason] says why.
final class DropFailed extends DropPhase {
  const DropFailed(this.reason);

  final String reason;
}
