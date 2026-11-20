import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/models/models.dart';
import 'package:remote_input/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

class HostPendingCard extends StatelessWidget {
  const HostPendingCard({super.key, required this.pending});

  final ConsentRequest pending;

  @override
  Widget build(BuildContext context) {
    final l10n = context.remoteInputL10n;
    final viewModel = context.read<HostViewModel>();

    return FeatureCard(
      icon: switch (pending.kind) {
        .control => LucideIcons.mousePointerClick,
        .screen => LucideIcons.keyboard,
        .lock => LucideIcons.lock,
      },
      iconTone: .accent,
      title: l10n.consentTitleOf(pending, HostKind.here),
      subtitle: l10n.consentBodyOf(pending),
      actions: [
        Button(
          mainAxisSize: .min,
          variant: .primary,
          label: l10n.allowAlways,
          onPressed: () => unawaited(viewModel.answer(.always)),
        ),
        GhostButton(
          mainAxisSize: .min,
          label: l10n.allowOnce,
          onPressed: () => unawaited(viewModel.answer(.allowOnce)),
        ),
        GhostButton(
          mainAxisSize: .min,
          label: l10n.dontAllow,
          onPressed: () => unawaited(viewModel.answer(.deny)),
        ),
      ],
    );
  }
}
