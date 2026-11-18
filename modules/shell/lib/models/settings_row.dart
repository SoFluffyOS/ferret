import 'package:feature_kit/feature_kit.dart';

/// One row of Settings: a group and every feature's part of it.
class SettingsRow {
  const SettingsRow(this.group, this.sections);

  final SettingsGroup group;
  final List<FeatureSettings> sections;

  /// The rows that have something behind them, in the order of
  /// [SettingsGroup]. A group no feature has a part in isn't a row.
  static List<SettingsRow> from(List<FeatureSettings> sections) => [
    for (final group in SettingsGroup.values)
      if (sections.where((section) => section.group == group).toList()
          case final parts when parts.isNotEmpty)
        SettingsRow(group, parts),
  ];

  /// The parts that can be on or off.
  List<FeatureSettings> get switchable => [
    for (final section in sections)
      if (section.isOn != null) section,
  ];

  /// The parts that are on.
  List<FeatureSettings> get on => [
    for (final section in sections)
      if (section.isOn ?? false) section,
  ];

  /// Something the person turned on isn't working.
  bool get needsAttention => sections.any((section) => section.needsAttention);
}
