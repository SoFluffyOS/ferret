import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/models/settings_pick.dart';

/// How a row of Settings is recognised before it is read: its icon, on a
/// tile in the colour that is its own.
typedef SettingsPlace = ({IconData icon, PlaceColor color});

extension SettingsGroupPlace on SettingsGroup {
  SettingsPlace get place => switch (this) {
    .clipboard => (icon: LucideIcons.clipboard, color: .blue),
    .files => (icon: LucideIcons.folder, color: .teal),
    .continueAndMedia => (icon: LucideIcons.play, color: .pink),
    .phone => (icon: LucideIcons.smartphone, color: .green),
    .control => (icon: LucideIcons.mousePointer2, color: .purple),
    .otherApps => (icon: LucideIcons.blocks, color: .orange),
  };
}

extension SettingsPickPlace on SettingsPick {
  SettingsPlace get place => switch (this) {
    ThisDevicePick() => (icon: LucideIcons.monitor, color: .indigo),
    GroupPick(:final group) => group.place,
    DoMorePick() => (icon: LucideIcons.sparkles, color: .orange),
    AdvancedPick() => (icon: LucideIcons.slidersHorizontal, color: .grey),
    AboutPick() => (icon: LucideIcons.info, color: .brown),
  };
}
