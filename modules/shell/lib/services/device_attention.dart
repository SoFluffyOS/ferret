import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// Features that are on and not working with one device, by name: what
/// turns its dot orange, and why.
abstract final class DeviceAttention {
  static List<({String title, FeatureHealth health})> of(
    BuildContext context,
    List<FeatureUi> features,
    FeatureContext featureContext,
    DeviceStatus device,
  ) => [
    for (final feature in features)
      if (feature.healthFor(featureContext, device) case final health?
          when isBroken(health))
        (title: feature.title(context), health: health),
  ];

  /// Needs the user, or tried and failed.
  static bool isBroken(FeatureHealth health) => switch (health.state) {
    .needsAttention || .failing => true,
    .ok || .off => false,
  };
}
