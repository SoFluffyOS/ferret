import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/feature_changes_listener.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Every feature that could be set up, in one compact card, instead of a
/// setup card per feature.
class OffersCard extends StatelessWidget {
  const OffersCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ShellScope.of(context);

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) {
        final offers = [
          for (final feature in scope.features)
            ?feature.offerFor(context, scope.featureContext),
        ];
        if (offers.isEmpty) {
          return const SizedBox.shrink();
        }

        final l10n = context.shellL10n;
        return Padding(
          padding: EdgeInsets.only(bottom: Spacing.d8),
          child: FeatureCard(
            icon: LucideIcons.sparkles,
            title: l10n.offersTitle,
            subtitle: l10n.offersSubtitle,
            children: [for (final offer in offers) _OfferRow(offer: offer)],
          ),
        );
      },
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({required this.offer});

  final FeatureOffer offer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  offer.title,
                  style: typography.base2.copyWith(color: palette.text),
                ),
                Text(
                  offer.description,
                  style: typography.caption1.copyWith(color: palette.mutedText),
                ),
              ],
            ),
          ),
          Spacing.h12,
          RowActionButton(label: offer.actionLabel, onPressed: offer.onAction),
        ],
      ),
    );
  }
}
