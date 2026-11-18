import 'package:feature_kit/widgets/feature_card.dart';
import 'package:flutter/widgets.dart';

/// One line in Home's Activity list: something that just happened with a
/// device ("Copied on Pixel 9"), or, when [pinned], something going on right
/// now (a call, a transfer, a song playing).
///
/// Features return these from `FeatureUi.activity`; the shell draws them,
/// newest first, so every feature's trace reads the same.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.icon,
    required this.title,
    this.detail,
    this.at,
    this.pinned = false,
    this.progress,
    this.tone = .normal,
    this.actions = const [],
    this.onTap,
  });

  /// Stays the same while the line is about the same thing, and is unique
  /// within the feature, such as a transfer's id.
  final String id;

  final IconData icon;

  /// What happened and with which device, such as "Copied on Pixel 9" or
  /// "IMG_2041.jpg from Pixel 9".
  final String title;

  /// The second line: a preview, or where it went ("Saved to Downloads").
  /// Never anything the feature marks as sensitive.
  final String? detail;

  /// When it happened. The shell sorts by it and shows it as "now" or
  /// "2 min". A pinned line may leave it out.
  final DateTime? at;

  /// Going on right now: an incoming call, a running transfer, media
  /// playing, this device being controlled. Pinned lines sit above the
  /// others and don't count toward the three Home shows.
  final bool pinned;

  /// From 0 to 1 while bytes move, drawn as a thin bar under the line.
  final double? progress;

  /// The icon's colour by meaning, such as danger for a transfer that
  /// failed.
  final FeatureTone tone;

  /// At most two things to do about it, such as Copy, Open, or Answer and
  /// Decline.
  final List<ActivityAction> actions;

  /// Opens the full story, such as the list of notifications.
  final VoidCallback? onTap;
}

/// Something to do about an [ActivityItem], shown at the end of its line.
class ActivityAction {
  const ActivityAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
  });

  /// A verb, such as "Copy" or "Open". With an [icon] it is the tooltip.
  final String label;

  /// Draws the action as an icon button, for controls everyone knows by
  /// sight such as play and next.
  final IconData? icon;

  /// The one thing to do right now, such as "Answer". Drawn filled.
  final bool primary;

  final VoidCallback onPressed;
}
