import 'dart:async';

import 'package:core/core.dart';
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

/// One feature's offer, with the feature it comes from.
typedef OfferOf = ({String featureId, FeatureOffer offer});

/// Builds with every offer that fits the devices paired now, and again
/// whenever a pairing or a feature changes what is on offer.
class OffersBuilder extends StatelessWidget {
  const OffersBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, List<OfferOf> offers) builder;

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
      builder: (context) => builder(context, [
        for (final feature in scope.features)
          if (offered.contains(feature.featureId))
            if (feature.offerFor(context, scope.featureContext)
                case final offer?)
              (featureId: feature.featureId, offer: offer),
      ]),
    );
  }
}

/// Every feature that could be set up, in one compact card, instead of a
/// setup card per feature. The ✕ hides it until a feature that wasn't on
/// offer then has something new; Settings → Do more keeps them all.
class OffersCard extends StatefulWidget {
  const OffersCard({super.key});

  @override
  State<OffersCard> createState() => _OffersCardState();
}

class _OffersCardState extends State<OffersCard> {
  late final SettingsStore _settings;
  StreamSubscription<String>? _settingChanges;

  @override
  void initState() {
    super.initState();
    _settings = ShellScope.read(context).featureContext.engine.settings;
    _settingChanges = _settings.changes.listen((key) {
      if (key == OffersDismissal.dismissedKey && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    unawaited(_settingChanges?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dismissal = OffersDismissal(_settings);

    return OffersBuilder(
      builder: (context, offers) {
        final ids = {for (final offer in offers) offer.featureId};
        if (offers.isEmpty || dismissal.hides(ids)) {
          return const SizedBox.shrink();
        }

        final l10n = context.shellL10n;
        return Padding(
          padding: EdgeInsets.only(bottom: Spacing.d8),
          child: FeatureCard(
            icon: LucideIcons.sparkles,
            title: l10n.offersTitle,
            subtitle: l10n.offersSubtitle,
            trailing: _NotNowButton(
              onTap: () => unawaited(dismissal.dismiss(ids)),
            ),
            children: [OffersList(offers: offers)],
          ),
        );
      },
    );
  }
}

/// The small ✕ at the end of the card's title row.
class _NotNowButton extends StatelessWidget {
  const _NotNowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final isTouch = switch (context.fluffyTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => false,
      _ => true,
    };
    // A finger needs the HIG's 44 points; the icon stays small inside.
    final target = switch (isTouch) {
      true => Spacing.d44,
      false => Spacing.d24,
    };

    return Tappable(
      tooltip: l10n.offersNotNowTooltip,
      semanticLabel: l10n.offersNotNow,
      onTap: onTap,
      child: SizedBox.square(
        dimension: target,
        child: Center(
          child: Icon(
            LucideIcons.x,
            size: Spacing.d14,
            color: context.palette.mutedText,
          ),
        ),
      ),
    );
  }
}

/// The offers one under the other, on Home's card and in Settings.
class OffersList extends StatelessWidget {
  const OffersList({super.key, required this.offers});

  final List<OfferOf> offers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        for (final (index, offer) in offers.indexed) ...[
          if (index > 0) Spacing.v8,
          OfferRow(offer: offer.offer),
        ],
      ],
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
