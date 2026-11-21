import 'package:feature_kit/feature_kit.dart';

/// What Settings shows next to its list where there is room for both.
sealed class SettingsPick {
  const SettingsPick();
}

/// This device's name, and how Ferret runs on it.
final class ThisDevicePick extends SettingsPick {
  const ThisDevicePick();
}

/// One group of features.
final class GroupPick extends SettingsPick {
  const GroupPick(this.group);

  final SettingsGroup group;

  @override
  bool operator ==(Object other) => other is GroupPick && other.group == group;

  @override
  int get hashCode => group.hashCode;
}

/// Every extra that could be turned on, also once Home's card is waved off.
final class DoMorePick extends SettingsPick {
  const DoMorePick();
}

final class AdvancedPick extends SettingsPick {
  const AdvancedPick();
}

final class AboutPick extends SettingsPick {
  const AboutPick();
}
