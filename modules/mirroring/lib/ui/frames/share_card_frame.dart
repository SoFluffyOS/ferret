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
/// Stop while it lasts (also while that computer dropped off for a
/// moment), and the audit line once it is over. The same for its camera:
/// the question with Once, Always and No, then "Camera on for MacBook"
/// with Stop.
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
    final controlPending = context.select<ShareViewModel, ControlRequest?>(
      (viewModel) => viewModel.controlPending,
    );
    final controller = context.select<ShareViewModel, ControlRequest?>(
      (viewModel) => viewModel.controller,
    );
    final cameraPending = context.select<ShareViewModel, ShareRequest?>(
      (viewModel) => viewModel.cameraPending,
    );
    final cameraActive = context.select<ShareViewModel, ActiveCamera?>(
      (viewModel) => viewModel.cameraActive,
    );
    final viewModel = context.read<ShareViewModel>();
    final l10n = context.mirroringL10n;

    if (cameraPending != null) {
      return FeatureCard(
        icon: LucideIcons.video,
        iconTone: .accent,
        title: l10n.cameraAskTitle(cameraPending.deviceName),
        subtitle: l10n.cameraAskBody,
        actions: [
          Button(
            variant: .primary,
            label: l10n.controlOnce,
            onPressed: () => unawaited(viewModel.answerCamera(.once)),
          ),
          Button(
            variant: .ghost,
            label: l10n.controlAlways,
            onPressed: () => unawaited(viewModel.answerCamera(.always)),
          ),
          Button(
            variant: .ghost,
            label: l10n.controlNo,
            onPressed: () => unawaited(viewModel.answerCamera(.no)),
          ),
        ],
      );
    }

    if (cameraActive != null) {
      final since = l10n.time(cameraActive.startedAt);
      return FeatureCard(
        icon: LucideIcons.video,
        iconTone: .warning,
        title: l10n.cameraOnTitle(cameraActive.deviceName),
        subtitle: switch (cameraActive.withSound) {
          true => l10n.cameraOnBody(since, ThisComputer.handheld),
          false => l10n.cameraOnBodySilent(since, ThisComputer.handheld),
        },
        actions: [
          Button(
            variant: .primary,
            label: l10n.stop,
            onPressed: () => unawaited(viewModel.stopCamera()),
          ),
        ],
      );
    }

    if (controlPending != null) {
      return FeatureCard(
        icon: LucideIcons.mousePointerClick,
        iconTone: .accent,
        trailing: const MirroringBetaTag(.wifiControl),
        title: l10n.controlAskCardTitle(
          controlPending.deviceName,
          viewModel.phoneName,
        ),
        subtitle: l10n.controlAskBody(controlPending.deviceName),
        actions: [
          Button(
            variant: .primary,
            label: l10n.controlOnce,
            onPressed: () => unawaited(viewModel.answerControl(.once)),
          ),
          Button(
            variant: .ghost,
            label: l10n.controlAlways,
            onPressed: () => unawaited(viewModel.answerControl(.always)),
          ),
          Button(
            variant: .ghost,
            label: l10n.controlNo,
            onPressed: () => unawaited(viewModel.answerControl(.no)),
          ),
        ],
      );
    }

    if (active != null && controller != null) {
      return FeatureCard(
        icon: LucideIcons.mousePointerClick,
        iconTone: .warning,
        title: l10n.controlledTitle(controller.deviceName),
        subtitle: l10n.controlledBody,
        actions: [
          Button(
            variant: .primary,
            label: l10n.controlStop,
            onPressed: () => unawaited(viewModel.stopControl()),
          ),
          Button(
            variant: .ghost,
            label: l10n.controlStopSharing,
            onPressed: () => unawaited(viewModel.stop()),
          ),
        ],
      );
    }

    if (active != null) {
      return FeatureCard(
        icon: LucideIcons.screenShare,
        iconTone: .warning,
        title: switch (active.withSound) {
          true => l10n.sharingTitleSound(active.deviceName),
          false => l10n.sharingTitle(active.deviceName),
        },
        subtitle: switch ((active.reconnecting, active.withSound)) {
          (true, _) => l10n.sharingReconnecting(active.deviceName),
          (false, true) => l10n.sharingBodySound(l10n.time(active.startedAt)),
          (false, false) => l10n.sharingBody(l10n.time(active.startedAt)),
        },
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
      title: switch (record.camera) {
        true => l10n.cameraTitle,
        false => l10n.title,
      },
      subtitle: l10n.audit(record),
      trailing: DismissButton(
        label: l10n.dismiss,
        onTap: viewModel.dismissRecord,
      ),
    );
  }
}
