import 'package:flutter/widgets.dart';

/// Something a feature could do once the user sets it up, such as "Read and
/// reply to texts from your computer". The shell gathers every offer in one
/// "Turn on more" card instead of a setup card per feature.
class FeatureOffer {
  const FeatureOffer({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  /// The feature's name, such as "Messages".
  final String title;

  /// One line on what it does for the user.
  final String description;

  /// Such as "Set up".
  final String actionLabel;

  final VoidCallback onAction;
}
