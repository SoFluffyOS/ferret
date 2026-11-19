import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What is going on right now with one device (a call, a transfer, a song),
/// at the top of its Overview in a window too narrow for the Activity pane,
/// or with the pane hidden. Takes no room otherwise: Home and the pane
/// already show these lines.
class DeviceNowFrame extends StatelessWidget {
  const DeviceNowFrame({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final isPaneHidden = context.select<WindowNavViewModel?, bool>(
      (viewModel) => viewModel?.isActivityPaneHidden ?? false,
    );
    final hasPane = context.screenSize >= ScreenSize.larger && !isPaneHidden;
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
        if (feed.pinned.isEmpty) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();

        return Padding(
          padding: EdgeInsets.only(bottom: Spacing.d12),
          child: SurfaceCard(
            padding: EdgeInsets.symmetric(vertical: Spacing.d6),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                for (final item in feed.pinned)
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
