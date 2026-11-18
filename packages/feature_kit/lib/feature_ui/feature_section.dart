import 'package:flutter/widgets.dart';

/// A page of a feature for one device, such as its texts. On a phone it is
/// pushed; in a window it fills the pane next to the device list, under the
/// device's name.
class FeatureSection {
  const FeatureSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.order,
    required this.builder,
    this.badge,
    this.fillsPane = false,
    this.isSetUp = true,
  });

  /// The section every device has: its own page.
  static const overviewId = 'overview';

  /// Unique among a device's sections, such as `messages`.
  final String id;

  /// What the device list calls it, such as "Messages".
  final String title;

  final IconData icon;

  /// Where it sits under the device, lowest first: Messages 10, Calls 20,
  /// Notifications 30, Files 40, Screen 50.
  final int order;

  /// The page itself: the same one wherever it shows.
  final WidgetBuilder builder;

  /// A count next to the title, such as unread conversations. Null or zero
  /// shows nothing.
  final int? badge;

  /// Whether the page lays itself out across the whole pane, such as a
  /// conversation list next to a thread.
  final bool fillsPane;

  /// False while the feature is off for this device: the row is dimmed, and
  /// the page says how to turn it on.
  final bool isSetUp;
}
