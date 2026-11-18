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

/// "Show screen" on an iPhone or iPad: the three steps to do there, with
/// the name to look for, while this computer listens for two minutes. The
/// device that then connects is confirmed right here.
class AirplayGuideFrame extends StatelessWidget {
  const AirplayGuideFrame({
    super.key,
    required this.deviceName,
    required this.onCancel,
    this.clock,
  });

  final String deviceName;
  final VoidCallback onCancel;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final request = context.select<ViewerViewModel, IncomingRequest?>(
      (viewModel) => viewModel.requests.firstOrNull,
    );
    final defers = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.airplayDefersToSystem,
    );
    final timedOut = context.select<ViewerViewModel, bool>(
      (viewModel) => viewModel.airplayTimedOut,
    );
    final armedUntil = context.select<ViewerViewModel, DateTime?>(
      (viewModel) => viewModel.armedUntil,
    );
    final computerName = context.select<ViewerViewModel, String>(
      (viewModel) => viewModel.computerName,
    );
    final viewModel = context.read<ViewerViewModel>();
    final l10n = context.mirroringL10n;
    final cancel = MessageAction(label: l10n.cancel, onPressed: onCancel);

    if (request != null) {
      return MirrorMessage(
        icon: LucideIcons.screenShare,
        tone: .accent,
        title: l10n.airplayConnecting(request.deviceName),
        body: l10n.airplayConnectingBody,
        actions: [
          MessageAction(
            label: l10n.notMine,
            onPressed: () => viewModel.answer(request, allow: false),
          ),
          MessageAction(
            label: l10n.showIt,
            primary: true,
            onPressed: () => viewModel.answer(request, allow: true),
          ),
        ],
      );
    }

    if (defers) {
      return MirrorMessage(
        icon: LucideIcons.airplay,
        title: l10n.airplayMacTitle,
        body: l10n.airplayMacBody(deviceName),
        actions: [
          MessageAction(label: l10n.close, onPressed: onCancel),
          MessageAction(
            label: l10n.useFerretAnyway,
            onPressed: () => unawaited(viewModel.useFerretAnyway()),
          ),
        ],
      );
    }

    if (timedOut) {
      return MirrorMessage(
        icon: LucideIcons.airplay,
        title: l10n.airplayTimedOutTitle,
        body: l10n.airplayTimedOutBody,
        actions: [
          MessageAction(label: l10n.close, onPressed: onCancel),
          MessageAction(
            label: l10n.listenAgain,
            primary: true,
            onPressed: () => unawaited(viewModel.listenAgain()),
          ),
        ],
      );
    }

    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final caption = typography.caption1.copyWith(color: palette.mutedText);

    return MirrorMessage(
      icon: LucideIcons.airplay,
      tone: .accent,
      title: l10n.airplayOn(deviceName),
      actions: [cancel],
      children: [
        Spacing.v8,
        for (final (index, line) in [
          l10n.airplayStep1,
          l10n.airplayStep2,
          l10n.airplayStep3(computerName),
        ].indexed)
          Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.d2),
            child: Text(
              '${index + 1}. $line',
              textAlign: .center,
              style: typography.base2.copyWith(color: palette.text),
            ),
          ),
        Spacing.v12,
        if (armedUntil != null)
          Countdown(
            until: armedUntil,
            clock: clock,
            builder: (context, left) => Text(
              '${l10n.airplayListening} ${Countdown.clockText(left)}',
              style: caption,
            ),
          ),
        Spacing.v8,
        Text(l10n.airplayNote, textAlign: .center, style: caption),
      ],
    );
  }
}
