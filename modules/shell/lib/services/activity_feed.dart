import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// Every feature's activity as Home shows it: what is going on right now
/// first, then what happened, newest first.
class ActivityFeed {
  const ActivityFeed({required this.pinned, required this.recent});

  /// Asks each of [features] what it did, and sorts the answers.
  factory ActivityFeed.gather(
    BuildContext context,
    List<FeatureUi> features,
    FeatureContext featureContext,
  ) {
    final items = [
      for (final feature in features)
        ...feature.activity(context, featureContext),
    ];

    return ActivityFeed(
      pinned: [
        for (final item in items)
          if (item.pinned) item,
      ],
      recent: [
        for (final item in items)
          if (!item.pinned) item,
      ]..sort(_newestFirst),
    );
  }

  static final _longAgo = DateTime.fromMillisecondsSinceEpoch(0);

  final List<ActivityItem> pinned;
  final List<ActivityItem> recent;

  bool get isEmpty => pinned.isEmpty && recent.isEmpty;

  static int _newestFirst(ActivityItem a, ActivityItem b) =>
      (b.at ?? _longAgo).compareTo(a.at ?? _longAgo);
}
