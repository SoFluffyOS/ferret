import 'package:feature_kit/services/services.dart';
import 'package:feature_kit/widgets/widgets.dart';
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
    this.needsYou = false,
    this.leading,
    this.trailing,
    this.progress,
    this.tone = .normal,
    this.actions = const [],
    this.onTap,
    this.onDismiss,
    this.deviceId,
    this.files = const [],
    this.private,
  });

  /// Stays the same while the line is about the same thing, and is unique
  /// within the feature, such as a transfer's id.
  final String id;

  final IconData icon;

  /// What happened and with which device, such as "Copied on Pixel 9" or
  /// "IMG_2041.jpg from Pixel 9".
  final String title;

  /// The paired device this happened with, so a window can show the line
  /// next to that device. Null when it is about no device in particular,
  /// or about one that isn't paired.
  final String? deviceId;

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

  /// Waits for the person's answer, such as a file from a device that
  /// isn't paired. These lines sit under "Needs you" at the top of Home,
  /// above the devices, instead of in Activity.
  final bool needsYou;

  /// Drawn in place of [icon], such as the caller's photo.
  final Widget? leading;

  /// Drawn at the end of the first line in place of the time, such as a
  /// call's running timer.
  final Widget? trailing;

  /// From 0 to 1 while bytes move, drawn as a thin bar under the line.
  final double? progress;

  /// The icon's colour by meaning, such as danger for a transfer that
  /// failed.
  final FeatureTone tone;

  /// At most three things to do about it, such as Copy, Open, or Answer,
  /// Decline and Silence.
  final List<ActivityAction> actions;

  /// Opens the full story, such as the list of notifications.
  final VoidCallback? onTap;

  /// Paths of the files on this device the line is about, such as a file
  /// that just arrived. On a Mac the line can then be dragged to Finder or
  /// another app, and Space shows them in Quick Look. Never a `content://`
  /// URI.
  final List<String> files;

  /// Takes the line away, behind a small ✕ at its end. Null when the line
  /// goes by itself, such as a call that ended.
  final VoidCallback? onDismiss;

  /// Set when the title or detail say something private, such as a text
  /// or a notification. See [PrivateContent].
  final PrivateContent? private;

  /// This line with [private]'s cover as its title, [detail] in place of
  /// the content, and no picture or files.
  ActivityItem covered(String detail) => ActivityItem(
    id: id,
    icon: icon,
    title: private?.cover ?? title,
    detail: detail,
    at: at,
    pinned: pinned,
    needsYou: needsYou,
    trailing: trailing,
    progress: progress,
    tone: tone,
    actions: actions,
    onTap: onTap,
    onDismiss: onDismiss,
    deviceId: deviceId,
  );
}

/// Something to do about an [ActivityItem], shown at the end of its line.
class ActivityAction {
  const ActivityAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.tooltip,
  });

  /// A verb, such as "Copy" or "Open". With an [icon] it is the tooltip.
  final String label;

  /// The whole sentence a short [label] stands for, such as "Add iPad to
  /// this Mac" for "Add". Shown on hover and read out instead of [label].
  final String? tooltip;

  /// Draws the action as an icon button, for controls everyone knows by
  /// sight such as play and next.
  final IconData? icon;

  /// The one thing to do right now, such as "Answer". Drawn filled.
  final bool primary;

  final VoidCallback onPressed;
}
