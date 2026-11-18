import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// The pages features have for one device, in the order the device list
/// shows them under its Overview.
abstract final class DeviceSections {
  static List<FeatureSection> of(
    BuildContext context,
    List<FeatureUi> features,
    FeatureContext featureContext,
    DeviceStatus device,
  ) {
    final sections = [
      for (final feature in features)
        ...feature.deviceSections(context, featureContext, device),
    ];

    return [
      for (final (index, section) in sections.indexed) (index, section),
    ].sorted.toList();
  }
}

extension on List<(int, FeatureSection)> {
  /// By [FeatureSection.order], then as the features gave them.
  Iterable<FeatureSection> get sorted {
    sort((a, b) {
      final byOrder = a.$2.order.compareTo(b.$2.order);
      if (byOrder != 0) {
        return byOrder;
      }

      return a.$1.compareTo(b.$1);
    });

    return map((entry) => entry.$2);
  }
}
