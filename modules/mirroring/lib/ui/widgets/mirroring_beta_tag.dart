import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:mirroring/l10n/l10n.dart';

/// "Beta" beside a screen feature that hasn't met enough real devices yet.
class MirroringBetaTag extends StatelessWidget {
  const MirroringBetaTag(this.feature, {super.key});

  final BetaFeature feature;

  @override
  Widget build(BuildContext context) {
    final l10n = context.mirroringL10n;

    return BetaTag(feature, label: l10n.beta, tooltip: l10n.betaTooltip);
  }
}
