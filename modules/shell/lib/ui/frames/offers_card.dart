import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
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
    // Rebuilds when a pairing brings the first computer, or takes the last.
    final offered = context.select<EngineHost, Set<String>>(
      (host) => {
        for (final feature in scope.features)
          if (FeatureAccess.offeredWith(feature.featureId, [
            for (final status in host.devices) status.device.platform,
          ]))
            feature.featureId,
      },
    );

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) {
        final offers = [
          for (final feature in scope.features)
            if (offered.contains(feature.featureId))
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
            children: [
              for (final (index, offer) in offers.indexed) ...[
                if (index > 0) Spacing.v8,
                OfferRow(offer: offer),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// One thing to set up: what it is, and its button beside it, or under it
/// at large text.
class OfferRow extends StatelessWidget {
  const OfferRow({super.key, required this.offer});

  final FeatureOffer offer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;

    final text = Column(
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
    );
    final button = RowActionButton(
      label: offer.actionLabel,
      onPressed: offer.onAction,
    );

    // At large text the words beside the button would wrap a word a line.
    if (context.hasLargeText) {
      return Column(
        crossAxisAlignment: .start,
        children: [text, Spacing.v8, button],
      );
    }

    return Row(
      children: [
        Expanded(child: text),
        Spacing.h12,
        button,
      ],
    );
  }
}
