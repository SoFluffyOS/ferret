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
    return ActivityFeed.of([
      for (final feature in features)
        ...feature.activity(context, featureContext),
    ]);
  }

  /// Sorts [items] into Needs you, what is going on now and what happened.
  factory ActivityFeed.of(List<ActivityItem> items) {
    return ActivityFeed(
      needsYou: [
        for (final item in items)
          if (item.needsYou && !item.pinned) item,
        for (final item in items)
          if (item.needsYou && item.pinned) item,
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

  /// Shown under "Needs you", not in Activity. What waits quietly for an
  /// answer, such as a file offer, comes before what is going on right now,
  /// such as a ringing call, so it keeps the filled button.
  final List<ActivityItem> needsYou;

  final List<ActivityItem> pinned;
  final List<ActivityItem> recent;

  bool get isEmpty => pinned.isEmpty && recent.isEmpty;

  /// The lines about the device [deviceId], with those about no device in
  /// particular, such as a song playing here.
  ActivityFeed withDevice(String deviceId) {
    bool concerns(ActivityItem item) =>
        item.deviceId == null || item.deviceId == deviceId;

    return ActivityFeed(
      needsYou: needsYou.where(concerns).toList(),
      pinned: pinned.where(concerns).toList(),
      recent: recent.where(concerns).toList(),
    );
  }

  /// Only the lines about [deviceId], for Activity's filter by device.
  ActivityFeed fromDevice(String deviceId) {
    bool concerns(ActivityItem item) => item.deviceId == deviceId;

    return ActivityFeed(
      needsYou: needsYou.where(concerns).toList(),
      pinned: pinned.where(concerns).toList(),
      recent: recent.where(concerns).toList(),
    );
  }

  /// The devices the lines are about, the one with the newest line first.
  List<String> get deviceIds => {
    for (final item in [...pinned, ...recent]) ?item.deviceId,
  }.toList();

  /// The line that holds Home's one filled button: the first thing waiting
  /// for an answer (a file offer, then a ringing call), or else the first
  /// thing going on right now. Null leaves it to the first device's first
  /// action.
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
