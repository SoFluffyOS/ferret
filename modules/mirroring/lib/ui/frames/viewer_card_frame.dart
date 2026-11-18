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

/// The computer's card: the phone being asked or shown, with Open and
/// Stop, and the audit line once it is over.
class ViewerCardFrame extends StatelessWidget {
  const ViewerCardFrame({super.key, required this.onOpen});

  /// Opens the mirror page for the session's phone.
  final void Function(ViewSession session) onOpen;

  @override
  Widget build(BuildContext context) {
    final current = context.select<ViewerViewModel, ViewSession?>(
      (viewModel) => viewModel.current,
    );
    final record = context.select<ViewerViewModel, MirrorRecord?>(
      (viewModel) => viewModel.lastRecord,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;

    if (current != null && current.isLive) {
      final (title, subtitle) = switch (current.startedAt) {
        final startedAt? => (
          l10n.viewingTitle(current.deviceName),
          l10n.sinceTime(l10n.time(startedAt)),
        ),
        null => (
          l10n.viewingWaitingTitle(current.deviceName),
          l10n.viewingWaitingBody,
        ),
      };

      return FeatureCard(
        icon: LucideIcons.screenShare,
        iconTone: .accent,
        title: title,
        subtitle: subtitle,
        actions: [
          Button(
            variant: .primary,
            label: l10n.open,
            onPressed: () => onOpen(current),
          ),
          Button(
            variant: .ghost,
            label: l10n.stop,
            onPressed: () => unawaited(viewModel.stop()),
          ),
        ],
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
