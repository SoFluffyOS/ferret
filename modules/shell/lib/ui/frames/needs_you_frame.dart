import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What waits for the person's answer, such as a file from a device that
/// isn't paired, at the top of Home. Takes no space when nothing waits.
class NeedsYouFrame extends StatelessWidget {
  const NeedsYouFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) {
        final feed = ActivityFeed.gather(
          context,
          scope.features,
          scope.featureContext,
        );
        final waiting = feed.needsYou;
        if (waiting.isEmpty) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();

        return Padding(
          padding: EdgeInsets.only(bottom: Spacing.d8),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              SectionTitle(context.shellL10n.needsYouTitle),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    for (final item in waiting)
                      ActivityRow(
                        key: ValueKey(item.id),
                        item: item,
                        now: now,
                        holdsPrimary: identical(item, feed.primaryItem),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
