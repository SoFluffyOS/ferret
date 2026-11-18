import 'package:feature_kit/feature_ui/settings_group.dart';
import 'package:flutter/widgets.dart';

/// One feature's part of a Settings page: which row it sits behind, what it
/// is called there, and how it is doing, so the row can say so without
/// opening the page.
class FeatureSettings {
  const FeatureSettings({
    required this.group,
    required this.title,
    required this.child,
    this.summary = '',
    this.isOn,
    this.needsAttention = false,
  });

  final SettingsGroup group;

  /// The heading above [child], such as "Notifications".
  final String title;

  /// The settings themselves.
  final Widget child;

  /// The current state in a few words, such as "Syncs by itself" or
  /// "To Downloads". Shown as the row's value when the row holds only this.
  final String summary;

  /// Whether this part is turned on, or null when it has no on and off.
  /// Rows that hold several parts count these: "2 of 4 on".
  final bool? isOn;

  /// True only when something the person turned on isn't working. Never for
  /// something that was simply never set up.
  final bool needsAttention;
}
