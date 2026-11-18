import 'package:find/l10n/l10n.dart';
import 'package:find/models/models.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Words and icons for a ring to another device.
extension FindLabels on FindLocalizations {
  String outgoingTitle(OutgoingRing ring) {
    final name = ring.deviceName;
    return switch (ring.phase) {
      .requesting => outgoingRequesting(name),
      .ringing => outgoingRinging(name),
      .found => outgoingFound(name),
      .timedOut => outgoingTimedOut(name),
      .stoppedHere => outgoingStoppedHere(name),
      .stoppedElsewhere => outgoingStoppedElsewhere(name),
      .noSound => outgoingNoSound(name),
      .unreachable => outgoingUnreachable(name),
      .notSupported => outgoingNotSupported(name),
      .lostConnection => outgoingLostConnection(name),
    };
  }

  /// What to do next, or null when the title says it all.
  String? outgoingDetail(OutgoingRing ring) => switch (ring.phase) {
    .ringing when ring.muted => outgoingRingingMuted(ring.deviceName),
    .ringing => outgoingRingingDetail,
    .noSound => outgoingNoSoundDetail,
    .unreachable => outgoingUnreachableDetail,
    .notSupported => outgoingNotSupportedDetail(ring.deviceName),
    .lostConnection => outgoingLostConnectionDetail,
    _ => null,
  };
}

/// The icon for where a ring to another device stands.
IconData outgoingIcon(OutgoingPhase phase) => switch (phase) {
  .requesting || .ringing => LucideIcons.bellRing,
  .found => LucideIcons.circleCheck,
  .timedOut || .stoppedHere || .stoppedElsewhere => LucideIcons.bellOff,
  .noSound => LucideIcons.volumeX,
  .unreachable || .notSupported || .lostConnection => LucideIcons.triangleAlert,
};
