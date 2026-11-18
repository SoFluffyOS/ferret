import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A wide window's trailing pane: what is going on right now, then the last
/// things that happened with the device the window shows. It follows the
/// window's width and the person's choice, never its own content: an empty
/// pane says what will show there instead of going away.
class ActivityPaneFrame extends StatefulWidget {
  const ActivityPaneFrame({super.key});

  /// How many finished lines fit before "See all".
  static const recentShown = 8;

  @override
  State<ActivityPaneFrame> createState() => _ActivityPaneFrameState();
}

class _ActivityPaneFrameState extends State<ActivityPaneFrame> {
  Timer? _minutes;

  /// Keeps "2 min" honest while nothing else changes.
  @override
  void initState() {
    super.initState();
    _minutes = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _minutes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = context.select<WindowNavViewModel, WindowDestination?>(
      (viewModel) => viewModel.selection,
    );
    final isHidden = context.select<WindowNavViewModel, bool>(
      (viewModel) => viewModel.isActivityPaneHidden,
    );
    final device = context.select<EngineHost, DeviceStatus?>(
      (host) => switch (selection) {
        DeviceDestination(:final deviceId) => host.statusOf(deviceId),
        _ => null,
      },
    );
    final screenSize = context.screenSize;
    final scope = ShellScope.of(context);
    if (isHidden ||
        device == null ||
        selection is! DeviceDestination ||
        screenSize < ScreenSize.larger) {
      return const SizedBox.shrink();
    }

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) {
        final fillsPane =
            DeviceSections.of(
              context,
              scope.features,
              scope.featureContext,
              device,
            ).any(
              (section) =>
                  section.id == selection.sectionId && section.fillsPane,
            );
        if (fillsPane && screenSize != .extraLarge) {
          return const SizedBox.shrink();
        }

        final feed = ActivityFeed.gather(
          context,
          scope.features,
          scope.featureContext,
        ).withDevice(device.device.id);

        return SizedBox(
          width: PaneWidths.activity,
          child: _Pane(
            feed: feed,
            deviceName: device.device.name,
            onSeeAll: () => context.read<WindowNavViewModel>().select(
              const ActivityDestination(),
            ),
          ),
        );
      },
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.feed,
    required this.deviceName,
    required this.onSeeAll,
  });

  final ActivityFeed feed;
  final String deviceName;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;
    final recent = feed.recent.take(ActivityPaneFrame.recentShown).toList();
    final hidesSome = recent.length < feed.recent.length;
    final now = DateTime.now();

    return ColoredBox(
      color: palette.surface,
      child: SafeArea(
        left: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Spacing.d12,
            Spacing.d8,
            Spacing.d12,
            Spacing.d24,
          ),
          children: [
            if (feed.pinned.isNotEmpty) SectionTitle(l10n.activityPaneNow),
            for (final item in feed.pinned)
              ActivityRow(
                key: ValueKey(item.id),
                item: item,
                now: now,
                holdsPrimary: identical(item, feed.primaryItem),
              ),
            SectionTitle(
              l10n.activityPaneRecent(deviceName),
              trailing: switch (hidesSome) {
                true => Tappable(
                  onTap: onSeeAll,
                  child: Text(
                    l10n.activitySeeAll,
                    style: typography.caption1.copyWith(color: palette.link),
                  ),
                ),
                false => null,
              },
            ),
            if (recent.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.d4,
                  vertical: Spacing.d8,
                ),
                child: Text(
                  l10n.activityPaneEmpty(deviceName),
                  style: typography.base2.copyWith(color: palette.mutedText),
                ),
              ),
            for (final item in recent)
              ActivityRow(
                key: ValueKey(item.id),
                item: item,
                now: now,
                holdsPrimary: false,
              ),
          ],
        ),
      ),
    );
  }
}
