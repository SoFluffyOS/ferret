import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What is going on right now with one device (a call, a transfer, a song),
/// at the top of its Overview in a window too narrow for the Activity pane,
/// or with the pane hidden. What just happened with it stays there a
/// little while too, such as the first photo that arrived, so it shows
/// where the person looks, with Open and Show in folder. Takes no room
/// otherwise: Home and the pane already show these lines.
class DeviceNowFrame extends StatelessWidget {
  const DeviceNowFrame({super.key, required this.deviceId});

  final String deviceId;

  /// How long the newest finished line stays at the top.
  static const justNow = Duration(minutes: 2);

  /// The newest finished line about [deviceId] in [feed], while it is
  /// newer than [justNow].
  static ActivityItem? justFinished(
    ActivityFeed feed,
    String deviceId,
    DateTime now,
  ) {
    for (final item in feed.recent) {
      if (item.deviceId != deviceId) {
        continue;
      }

      final at = item.at;
      if (at == null || now.difference(at) > justNow) {
        return null;
      }

      return item;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isPaneHidden = context.select<WindowNavViewModel?, bool>(
      (viewModel) => viewModel?.isActivityPaneHidden ?? false,
    );
    final hasPane = WindowLayout.showsActivityPane(context) && !isPaneHidden;
    if (!WindowLayout.splits(context) || hasPane) {
      return const SizedBox.shrink();
    }

    final scope = ShellScope.of(context);

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) {
        final feed = ActivityFeed.gather(
          context,
          scope.features,
          scope.featureContext,
        ).withDevice(deviceId);
        final now = DateTime.now();
        final lines = [
          ...feed.pinned,
          ?justFinished(feed, deviceId, now),
        ];
        if (lines.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.only(bottom: Spacing.d12),
          child: SurfaceCard(
            padding: EdgeInsets.symmetric(vertical: Spacing.d6),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                for (final item in lines)
                  ActivityRow(
                    key: ValueKey(item.id),
                    item: item,
                    now: now,
                    holdsPrimary: identical(item, feed.primaryItem),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
