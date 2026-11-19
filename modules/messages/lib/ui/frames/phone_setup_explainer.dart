import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class PhoneSetupExplainer extends StatelessWidget {
  const PhoneSetupExplainer({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.messagesL10n;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            l10n.explainer,
            style: typography.base1.copyWith(color: palette.text),
          ),
          Spacing.v4,
          Text(
            l10n.explainerDetail,
            style: typography.caption1.copyWith(color: palette.mutedText),
          ),
          Spacing.v12,
          Button(
            variant: .primary,
            label: l10n.turnOn,
            onPressed: context.read<PhoneSetupViewModel>().turnOn,
          ),
        ],
      ),
    );
  }
}
