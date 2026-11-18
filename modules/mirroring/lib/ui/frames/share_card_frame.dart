import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mirroring/l10n/l10n.dart';
import 'package:mirroring/models/models.dart';
import 'package:mirroring/ui/widgets/widgets.dart';
import 'package:mirroring/view_models/view_models.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// The phone's card: a computer asking, "Sharing screen with MacBook" with
/// Stop while it lasts, and the audit line once it is over.
class ShareCardFrame extends StatelessWidget {
  const ShareCardFrame({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = context.select<ShareViewModel, ShareRequest?>(
      (viewModel) => viewModel.pending,
    );
    final active = context.select<ShareViewModel, ActiveShare?>(
      (viewModel) => viewModel.active,
    );
    final record = context.select<ShareViewModel, MirrorRecord?>(
      (viewModel) => viewModel.lastRecord,
    );
    final viewModel = context.read<ShareViewModel>();
    final l10n = context.mirroringL10n;

    if (active != null) {
      return FeatureCard(
        icon: LucideIcons.screenShare,
        iconTone: .warning,
        title: l10n.sharingTitle(active.deviceName),
        subtitle: l10n.sharingBody(l10n.time(active.startedAt)),
        actions: [
          Button(
            variant: .primary,
            label: l10n.stop,
            onPressed: () => unawaited(viewModel.stop()),
          ),
        ],
      );
    }

    if (pending != null) {
      return FeatureCard(
        icon: LucideIcons.screenShare,
        iconTone: .accent,
        title: l10n.askingTitle(pending.deviceName),
        subtitle: l10n.askingBody,
      );
    }

    if (record == null) {
      return const SizedBox.shrink();
    }

    return FeatureCard(
      icon: LucideIcons.history,
      iconTone: .muted,
      title: l10n.title,
      subtitle: l10n.audit(record),
      trailing: DismissButton(
        label: l10n.dismiss,
        onTap: viewModel.dismissRecord,
      ),
    );
  }
}
