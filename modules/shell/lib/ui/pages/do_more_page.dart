import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/frames/offers_card.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Settings → Do more: the same extras as Home's card, here for good, also
/// after the card is waved off.
class DoMorePage extends StatelessWidget {
  const DoMorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return FerretPage(
      title: l10n.offersTitle,
      backLabel: l10n.back,
      children: [
        OffersBuilder(
          builder: (context, offers) => SurfaceCard(
            child: switch (offers.isEmpty) {
              true => Text(
                l10n.offersAllOn,
                style: typography.body2.copyWith(color: palette.mutedText),
              ),
              false => Column(
                crossAxisAlignment: .stretch,
                children: [
                  Text(
                    l10n.offersSubtitle,
                    style: typography.caption1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                  Spacing.v12,
                  OffersList(offers: offers),
                ],
              ),
            },
          ),
        ),
      ],
    );
  }
}
