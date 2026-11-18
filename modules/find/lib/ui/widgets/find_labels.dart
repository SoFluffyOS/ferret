import 'package:feature_kit/feature_kit.dart';
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
    .noSound => outgoingNoSoundDetail(ring.deviceName),
    .unreachable => outgoingUnreachableDetail(ring.deviceName),
    .notSupported => outgoingNotSupportedDetail(ring.deviceName),
    .lostConnection => outgoingLostConnectionDetail(ring.deviceName),
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

/// How a ring's outcome reads at a glance: found is good news, a ring that
/// couldn't reach or sound is a problem.
FeatureTone outgoingTone(OutgoingPhase phase) => switch (phase) {
  .requesting || .ringing => FeatureTone.accent,
  .found => FeatureTone.success,
  .timedOut || .stoppedHere || .stoppedElsewhere => FeatureTone.muted,
  .noSound ||
  .unreachable ||
  .notSupported ||
  .lostConnection => FeatureTone.danger,
};
