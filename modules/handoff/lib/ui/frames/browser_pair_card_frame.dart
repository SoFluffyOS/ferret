import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';
import 'package:handoff/view_models/handoff_view_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// "Allow Firefox to use Ferret?" with the code to compare, Allow and Deny.
class BrowserPairCardFrame extends StatelessWidget {
  const BrowserPairCardFrame({super.key, required this.request});

  final BrowserPairRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.handoffL10n;
    final viewModel = context.read<HandoffViewModel>();

    return FeatureCard(
      icon: LucideIcons.puzzle,
      iconTone: .accent,
      title: l10n.browserPairTitle(request.browser),
      subtitle: l10n.browserPairBody(request.spacedCode),
      actions: [
        Button(
          variant: .primary,
          label: l10n.browserPairAllow,
          mainAxisSize: .min,
          onPressed: () =>
              unawaited(viewModel.answerPair(request, allow: true)),
        ),
        Button(
          variant: .secondary,
          label: l10n.browserPairDeny,
          mainAxisSize: .min,
          onPressed: () =>
              unawaited(viewModel.answerPair(request, allow: false)),
        ),
      ],
    );
  }
}
