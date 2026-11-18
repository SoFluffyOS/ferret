import 'package:flutter/widgets.dart';

/// Something near this device that isn't paired with Ferret and that a
/// feature can still do one thing with, such as a phone on a cable whose
/// screen can be shown. The shell lists it under Nearby, next to the
/// devices that can be paired.
class FeatureNearbyRow {
  const FeatureNearbyRow({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  /// Unique among every feature's rows: start it with the feature id.
  final String id;

  /// The device's name.
  final String title;

  /// How it is here, such as "Cable".
  final String detail;

  final IconData icon;

  /// A verb and its object, such as "Show screen".
  final String actionLabel;

  final VoidCallback onAction;
}
