import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/health_row.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What turns a device's dot orange, at the top of its Overview: each
/// feature that is on and not working, with why and its fix. Nothing when
/// everything works.
class NeedsAttentionCard extends StatelessWidget {
  const NeedsAttentionCard({super.key, required this.features});

  final List<({String title, FeatureHealth health})> features;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.shellL10n;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d12),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            for (final (:title, :health) in features)
              HealthRow(
                key: ValueKey(title),
                title: title,
                health: health,
                howLabel: l10n.deviceHow,
                fixLabel: l10n.deviceFix,
              ),
          ],
        ),
      ),
    );
  }
}
