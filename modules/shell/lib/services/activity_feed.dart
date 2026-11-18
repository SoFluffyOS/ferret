import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// Every feature's activity as Home shows it: what waits for the person's
/// answer, apart at the top; then what is going on right now, then what
/// happened, newest first.
class ActivityFeed {
  const ActivityFeed({
    required this.pinned,
    required this.recent,
    this.needsYou = const [],
  });

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
      needsYou: [
        for (final item in items)
          if (item.needsYou) item,
      ],
      pinned: [
        for (final item in items)
          if (item.pinned && !item.needsYou) item,
      ],
      recent: [
        for (final item in items)
          if (!item.pinned && !item.needsYou) item,
      ]..sort(_newestFirst),
    );
  }

  static final _longAgo = DateTime.fromMillisecondsSinceEpoch(0);

  /// Shown under "Needs you", not in Activity.
  final List<ActivityItem> needsYou;

  final List<ActivityItem> pinned;
  final List<ActivityItem> recent;

  bool get isEmpty => pinned.isEmpty && recent.isEmpty;

  /// The line that holds Home's one filled button: the first thing waiting
  /// for an answer, or else the first thing going on right now, such as a
  /// call ringing. Null leaves it to the first device's first action.
  ActivityItem? get primaryItem {
    for (final item in [...needsYou, ...pinned]) {
      if (item.actions.any((action) => action.primary)) {
        return item;
      }
    }

    return null;
  }

  static int _newestFirst(ActivityItem a, ActivityItem b) =>
      (b.at ?? _longAgo).compareTo(a.at ?? _longAgo);
}
