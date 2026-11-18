import 'package:feature_kit/feature_kit.dart';

/// The order a device's page shows its actions in.
abstract final class DeviceActionOrder {
  /// Sorts after every action that has a place on Home.
  static const _pageOnly = 1 << 20;

  /// [actions] with Home's order first, then as the features gave them.
  /// An action that only opens one of [listedSections], the sections the
  /// device list shows right now, is left out: its row is already there.
  static List<FeatureAction> of(
    List<FeatureAction> actions, {
    Set<String> listedSections = const {},
  }) {
    final ordered = [
      for (final (index, action) in actions.indexed)
        if (!listedSections.contains(action.sectionId)) (index, action),
    ]..sort(_byHomeOrder);

    return [for (final (_, action) in ordered) action];
  }

  static int _byHomeOrder((int, FeatureAction) a, (int, FeatureAction) b) {
    final byOrder = (a.$2.homeOrder ?? _pageOnly).compareTo(
      b.$2.homeOrder ?? _pageOnly,
    );
    if (byOrder != 0) {
      return byOrder;
    }

    return a.$1.compareTo(b.$1);
  }
}
