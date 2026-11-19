import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What just happened across every feature: the things going on right now,
/// then the last few that finished. On Home it shows three and a way to
/// the rest; on its own page, everything.
class ActivityFrame extends StatefulWidget {
  const ActivityFrame({super.key, this.limit, this.onSeeAll});

  /// How many finished lines to show, or null for all of them. Lines about
  /// something still going on always show.
  final int? limit;

  /// Opens the full list. Offered only when [limit] hides something.
  final VoidCallback? onSeeAll;

  @override
  State<ActivityFrame> createState() => _ActivityFrameState();
}

class _ActivityFrameState extends State<ActivityFrame> {
  Timer? _minutes;

  /// The device the full list is narrowed to, or null for all of them.
  String? _deviceId;

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
    final scope = ShellScope.of(context);

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) {
        final everything = ActivityFeed.gather(
          context,
          scope.features,
          scope.featureContext,
        );
        final limit = widget.limit;
        final host = context.read<EngineHost>();
        final filterIds = switch (limit) {
          null => [
            for (final deviceId in everything.deviceIds)
              if (host.statusOf(deviceId) != null) deviceId,
          ],
          _ => const <String>[],
        };
        final filtersBy = switch (_deviceId) {
          final deviceId? when filterIds.contains(deviceId) => deviceId,
          _ => null,
        };
        final feed = switch (filtersBy) {
          final deviceId? => everything.fromDevice(deviceId),
          null => everything,
        };
        if (feed.isEmpty && limit != null) {
          return const SizedBox.shrink();
        }

        final l10n = context.shellL10n;
        final recent = switch (limit) {
          final limit? => feed.recent.take(limit).toList(),
          null => feed.recent,
        };
        final hidesSome = recent.length < feed.recent.length;
        final now = DateTime.now();

        return Column(
          crossAxisAlignment: .stretch,
          children: [
            if (limit != null)
              SectionTitle(
                l10n.activityTitle,
                trailing: switch (hidesSome && widget.onSeeAll != null) {
                  true => _SeeAll(onTap: widget.onSeeAll),
                  false => null,
                },
              ),
            if (filterIds.length > 1)
              FilterChips(
                labels: [
                  l10n.activityFilterAll,
                  for (final deviceId in filterIds)
                    host.statusOf(deviceId)?.device.name ?? deviceId,
                ],
                selected: switch (filtersBy) {
                  final deviceId? => filterIds.indexOf(deviceId) + 1,
                  null => 0,
                },
                onSelected: (index) => setState(
                  () => _deviceId = switch (index) {
                    0 => null,
                    _ => filterIds[index - 1],
                  },
                ),
              ),
            if (feed.isEmpty) _Empty(l10n.activityEmpty),
            for (final item in [...feed.pinned, ...recent])
              ActivityRow(
                key: ValueKey(item.id),
                item: item,
                now: now,
                holdsPrimary: identical(item, feed.primaryItem),
              ),
          ],
        );
      },
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextLink(label: context.shellL10n.activitySeeAll, onTap: onTap);
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Spacing.d24),
      child: Text(
        text,
        textAlign: .center,
        style: context.fluffyTheme.typography.base2.copyWith(
          color: context.palette.mutedText,
        ),
      ),
    );
  }
}
