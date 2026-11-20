import 'package:shell/models/files_drop_target.dart';

/// What a quick drop on the menubar icon did.
sealed class IconDropOutcome {
  const IconDropOutcome();
}

/// It goes to [target] once the undo window is over.
final class IconDropPending extends IconDropOutcome {
  const IconDropPending(this.target, this.count);

  final DeviceDropTarget target;
  final int count;
}

/// It stays on this computer, on the shelf.
final class IconDropKept extends IconDropOutcome {
  const IconDropKept();
}

/// It waits in the popover for a device to be picked.
final class IconDropHeld extends IconDropOutcome {
  const IconDropHeld();
}

/// Nothing took it.
final class IconDropRefused extends IconDropOutcome {
  const IconDropRefused();
}
